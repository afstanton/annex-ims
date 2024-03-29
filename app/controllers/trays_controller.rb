class TraysController < ApplicationController
  def index
    @tray = Tray.new
  end

  def scan
    begin
      @tray = GetTrayFromBarcode.call(params[:tray][:barcode])
      @size = TraySize.call(@tray.barcode)
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to trays_path
      return
    end
    redirect_to show_tray_path(id: @tray.id)
  end

  def show
    @tray = Tray.find(params[:id])
    @size = TraySize.call(@tray.barcode)
  end

  def associate
    @tray = Tray.find(params[:id])
    @size = TraySize.call(@tray.barcode)

    barcode = params[:barcode]

    if barcode == @tray.barcode
      redirect_to trays_path
      return
    end

    unless params[:force] == 'true'
      if !@tray.shelf.nil? && (@tray.shelf.barcode != barcode)
        flash[:error] = "#{@tray.barcode} belongs to #{@tray.shelf.barcode}, but #{barcode} was scanned."
        redirect_to wrong_shelf_path(id: @tray.id, barcode: barcode)
        return
      end
    end

    begin
      AssociateTrayWithShelfBarcode.call(@tray, barcode, current_user)
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to show_tray_path(id: @tray.id)
      return
    end

    full = ShelfFull.call(@tray.shelf)
    if full == ShelfFull::FULL
      flash[:notice] = 'shelf is full'
    elsif full == ShelfFull::OVER
      flash[:error] = 'shelf is over capacity'
    end

    redirect_to trays_path
  end

  # The only reason to get here is to set the tray's shelf to nil, so let's do that.
  def dissociate
    @tray = Tray.find(params[:id])
    @size = TraySize.call(@tray.barcode)

    if DissociateTrayFromShelf.call(@tray, current_user)
      redirect_to trays_path
    else
      raise 'unable to dissociate tray'
    end
  end

  def shelve
    @tray = Tray.find(params[:id])
    @size = TraySize.call(@tray.barcode)

    barcode = params[:barcode]

    unless params[:force] == 'true'
      if !@tray.shelf.nil? && (@tray.shelf.barcode != barcode)
        flash[:error] = "#{@tray.barcode} belongs to #{@tray.shelf.barcode}, but #{barcode} was scanned."
        redirect_to wrong_shelf_path(id: @tray.id, barcode: barcode)
        return
      end
    end

    if ShelveTray.call(@tray, current_user)
      redirect_to trays_path
    else
      raise 'unable to shelve tray'
    end
  end

  def unshelve
    @tray = Tray.find(params[:id])
    @size = TraySize.call(@tray.barcode)

    if UnshelveTray.call(@tray, current_user)
      redirect_to trays_path
    else
      raise 'unable to unshelve tray'
    end
  end

  # The only way to get here is if you've scanned the wrong shelf after scanning a tray
  def wrong_shelf
    @tray = Tray.find(params[:id])
    @barcode = params[:barcode]
  end

  # The only way to get here is if you've scanned the wrong item after scanning a tray
  def wrong_tray
    @tray = Tray.find(params[:id])
    @barcode = params[:barcode]
    @item = GetItemFromBarcode.call(barcode: @barcode, user_id: current_user.id)
  end

  # Should this area be pulled out into a separate controller? It's all about trays, but with items.
  def items
    @tray = Tray.new
  end

  def scan_item
    begin
      @tray = GetTrayFromBarcode.call(params[:tray][:barcode])
      @size = TraySize.call(@tray.barcode)
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to trays_items_path
      return
    end
    redirect_to show_tray_item_path(id: @tray.id)
  end

  def show_item
    @tray = Tray.find(params[:id])
    @used = @tray.used
    @unlimited = @tray.tray_type.unlimited
    if @unlimited
      @capacity = 'unlimited'
      @progress = 0.0
    else
      @capacity = @tray.capacity
      @progress = @used.to_f / @capacity
      @progress = @progress <= 1.0 ? @progress : 1.0
    end
    @style = @tray.style
    @size = TraySize.call(@tray.barcode)
    @barcode = params[:barcode]
    @thickness = params[:thickness]
  end

  def associate_item
    @tray = Tray.find(params[:id])
    @size = TraySize.call(@tray.barcode)

    barcode = params[:barcode]
    thickness = params[:thickness]

    if barcode == @tray.barcode
      redirect_to trays_items_path
      return
    end

    unless IsValidThickness.call(thickness)
      flash[:error] = 'select a valid thickness'
      redirect_to show_tray_item_path(id: @tray.id, barcode: barcode)
      return
    end

    # The system should validate the barcode against the stored regular expression(s)
    unless IsValidItem.call(barcode)
      flash[:error] = I18n.t('errors.barcode_not_valid', barcode: barcode)
      redirect_to invalid_tray_item_path(id: @tray.id, thickness: thickness, barcode: barcode)
      return
    end

    create_item(@tray, barcode, thickness)
  end

  def dissociate_item
    @tray = Tray.find(params[:id])
    @item = Item.find(params[:item_id])

    if params[:commit] == 'Unstock'
      if UnstockItem.call(@item, current_user)
        redirect_to show_tray_item_path(id: @tray.id)
      else
        raise 'unable to dissociate tray'
      end
    else
      if DissociateTrayFromItem.call(@item, current_user)
        redirect_to show_tray_item_path(id: @tray.id)
      else
        raise 'unable to dissociate tray'
      end
    end
  end

  def withdraw
    @tray = Tray.find(params[:id])

    WithdrawTray.call(@tray, current_user)

    redirect_to show_tray_path(id: @tray.id)
  end

  def missing
    @tray = Tray.find(params[:id])
  end

  def invalid
    @tray = Tray.find(params[:id])
    @thickness = params[:thickness]
    @barcode = params[:barcode]
    @set_aside_flag = true
  end

  def create_item(tray = Tray.find(params[:id]), barcode = params[:barcode], thickness = params[:thickness])
    result = CreateItem.call(tray, barcode, current_user.id, thickness, params[:flag])

    if result == 'errors.barcode_not_found'
      flash[:error] = I18n.t(result, barcode: barcode)
      redirect_to missing_tray_item_path(id: tray.id)
    elsif !result.nil?
      if result["Item #{barcode} is already assigned to"]
        flash[:error] = result
        redirect_to wrong_tray_path(id: tray.id, barcode: barcode)
      elsif result['Record updated.'] || result["Item #{barcode} stocked in"]
        flash[:notice] = result
        if TrayFull.call(tray)
          flash[:error] = 'warning - tray may be full'
        end
        redirect_to show_tray_item_path(id: tray.id)
      end
    else
      if !result.nil?
        Sentry.capture_exception(result)
        flash[:error] = result.message
      end
      redirect_to show_tray_item_path(id: tray.id)
    end
  end

  def check_items_new
    @tray = Tray.new
  end

  def check_items_find
    begin
      @tray = GetTrayFromBarcode.call(params[:tray][:barcode])
      @scanned = []
      @extras = []
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to check_items_new_path
      return
    end
    redirect_to check_items_path(barcode: @tray.barcode)
  end

  def check_items
    @tray = Tray.where(barcode: params[:barcode]).take
    @scanned = []
    @errors = []
  end

  def validate_items
    @tray = Tray.where(barcode: params[:barcode]).take
    item_barcode = params[:item_barcode]
    item = Item.where(barcode: item_barcode).take
    @scanned = params[:scanned].presence || []
    @errors = params[:errors].presence || []

    if item.nil?
      if IsValidItem.call(item_barcode)
        @errors.push(I18n.t('errors.barcode_not_found', barcode: item_barcode))
        item = Item.create!(barcode: item_barcode, thickness: 0)
        ActivityLogger.create_item(item: item, user: current_user)
        AddIssue.call(item: item,
                      user: current_user,
                      type: 'tray_mismatch',
                      message: "Item failed QC. Was physically in tray '#{@tray.barcode}', but the item did not exist.")
        SyncItemMetadata.call(item: item, user_id: current_user.id)
      else
        @errors.push(I18n.t('errors.barcode_not_valid', barcode: item_barcode))
      end

      @errors = @errors.uniq
      flash.now[:error] = @errors.join('<br>').html_safe if @errors.count > 0
      render :check_items
      return
    end

    if @tray.items.include?(item)
      @scanned.push(item_barcode)
      @scanned = @scanned.uniq
    else
      @errors.push(I18n.t('errors.barcode_not_associated_to_tray', barcode: item_barcode))
      but_message = item.tray.present? ? "but is associated with tray '#{item.tray.barcode}'" : 'but is not associated with a tray.'
      AddIssue.call(item: item,
                    user: current_user,
                    type: 'tray_mismatch',
                    message: "Item failed QC. Was physically in tray '#{@tray.barcode}', #{but_message}")
    end

    @errors = @errors.uniq
    flash.now[:error] = @errors.join('<br>').html_safe if @errors.count > 0
    render :check_items
  end

  def count_items
    if user_admin?
      redirect_to trays_items_path
      return
    end

    @tray = Tray.find(params[:id])
    @validation_count_items = params[:validation_count_items]
    tray_count = params[:tray_count]

    if !tray_count.nil?
      count_items_in_tray = @tray.items.count
      if tray_count.to_i != count_items_in_tray
        if @validation_count_items.nil?
          @validation_count_items = 0
        else
          @validation_count_items = @validation_count_items.to_i + 1
          if @validation_count_items == 2
            AddTrayIssue.call(user: current_user, tray: @tray, message: 'Tray count invalid', type: 'incorrect_count')
            flash[:error] = I18n.t('trays.count_validation_not_pass')
          else
            flash[:error] = I18n.t('trays.count_items_not_match')
          end
        end
      else
        tray_issue_query = IssuesForTrayQuery.new(barcode: @tray.barcode)
        if tray_issue_query.invalid_count_issues?
          tray_issue_query.issues_by_type(type: 'incorrect_count').each do |issue|
            ResolveTrayIssue.call(tray: @tray, issue: issue, user: current_user)
          end
        end
        redirect_to trays_items_path
      end
    end
  end

  def issues
    @issues = UnresolvedTrayIssueQuery.call(params)
  end

  def resolve
    tray = Tray.where(barcode: TrayIssue.find(params[:issue_id]).barcode).take!

    redirect_to count_tray_item_path(id: tray.id)
  end

  def tray_detail
    @tray = Tray.where(barcode: params[:barcode]).take
    if @tray
      @history = ActivityLogQuery.tray_history(@tray)
    end
  end
end
