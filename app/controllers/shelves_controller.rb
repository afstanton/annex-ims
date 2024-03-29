class ShelvesController < ApplicationController
  def index
    @shelf = Shelf.new
  end

  def scan
    begin
      @shelf = GetShelfFromBarcode.call(params[:shelf][:barcode])
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to shelves_path
      return
    end
    redirect_to show_shelf_path(id: @shelf.id)
  end

  def show
    @shelf = Shelf.find(params[:id])
  end

  def shelf_detail
    @shelf = Shelf.where(barcode: params[:barcode]).take
    unless !@shelf
      @trays = @shelf.trays
      @history = ActivityLogQuery.shelf_history(@shelf)
    end
  end

  def associate
    @shelf = Shelf.find(params[:id])

    barcode = params[:barcode]

    if barcode == @shelf.barcode
      redirect_to shelves_path
      return
    end

    thickness = 1 # Because we don't care about thickness here, it just needs to be something valid.

    item = GetItemFromBarcode.call(barcode: barcode, user_id: current_user.id)

    if item.nil?
      flash[:error] = I18n.t('errors.barcode_not_found', barcode: barcode)
      redirect_to missing_shelf_item_path(id: @shelf.id)
      return
    end

    already = false

    unless item.shelf.nil?
      if item.shelf != @shelf
        flash[:error] = "Item #{barcode} is already assigned to #{item.shelf.barcode}."
        redirect_to wrong_shelf_item_path(id: @shelf.id, barcode: barcode)
        return
      else
        already = true
      end
    end

    begin
      AssociateShelfWithItemBarcode.call(current_user.id, @shelf, barcode, thickness)
      flash[:notice] = if already
                         "Item #{barcode} already assigned to #{@shelf.barcode}. Record updated."
                       else
                         "Item #{barcode} stocked in #{@shelf.barcode}."
                       end
      redirect_to show_shelf_path(id: @shelf.id)
      nil
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to show_shelf_path(id: @shelf.id)
      nil
    end
  end

  def wrong
    @shelf = Shelf.find(params[:id])
    @barcode = params[:barcode]
  end

  def missing
    @shelf = Shelf.find(params[:id])
  end

  def dissociate
    @shelf = Shelf.find(params[:id])
    @item = Item.find(params[:item_id])

    if params[:commit] == 'Unstock'
      if UnstockItem.call(@item, current_user)
        redirect_to show_shelf_path(id: @shelf.id)
      else
        raise 'unable to unstock item'
      end
    else
      if DissociateShelfFromItem.call(@item, current_user)
        redirect_to show_shelf_path(id: @shelf.id)
      else
        raise 'unable to dissociate'
      end
    end
  end

  def check_trays_new
    @shelf = Shelf.new
  end

  def check_trays_find
    begin
      @shelf = GetShelfFromBarcode.call(params[:shelf][:barcode])
      @scanned = []
      @extras = []
    rescue StandardError => e
      Sentry.capture_exception(e)
      flash[:error] = e.message
      redirect_to check_trays_new_path
      return
    end
    redirect_to check_trays_path(barcode: @shelf.barcode)
  end

  def check_trays
    @shelf = Shelf.where(barcode: params[:barcode]).take
    @scanned = []
    @errors = []
  end

  def validate_trays
    @shelf = Shelf.where(barcode: params[:barcode]).take
    tray_barcode = params[:tray_barcode]
    tray = Tray.where(barcode: tray_barcode).take
    @scanned = params[:scanned].presence || []
    @errors = params[:errors].presence || []

    if tray.nil?
      if IsTrayBarcode.call(tray_barcode)
        @errors.push(I18n.t('errors.barcode_not_found', barcode: tray_barcode))
        tray = Tray.create!(barcode: tray_barcode)
        ActivityLogger.create_tray(tray: tray, user: current_user)
      else
        @errors.push(I18n.t('errors.barcode_not_valid', barcode: tray_barcode))
      end

      @errors = @errors.uniq
      flash.now[:error] = @errors.join('<br>').html_safe if @errors.count > 0
      render :check_trays
      return
    end

    if @shelf.trays.include?(tray)
      @scanned.push(tray_barcode)
      @scanned = @scanned.uniq
    else
      @errors.push(I18n.t('errors.barcode_not_associated_to_shelf', barcode: tray_barcode))
      tray.shelf.present? ? "but is associated with shelf '#{tray.shelf.barcode}'" : 'but is not associated with a shelf.'
    end

    @errors = @errors.uniq
    flash.now[:error] = @errors.join('<br>').html_safe if @errors.positive?
    render :check_trays
  end
end
