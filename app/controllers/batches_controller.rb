class BatchesController < ApplicationController
  before_action :require_admin
  def index
    # Should this be in a service object? It's a relatively simple one-liner.
    requests = Request.all.where('id NOT IN (SELECT request_id FROM matches)')
    @data = BuildRequestData.call(requests)

    if current_batch?
      flash[:notice] = flash_message('active_batch')
      redirect_to current_batch_path
      return
    end

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def create
    if batch_blank?
      flash[:error] = flash_message('empty_batch')
      redirect_to batches_path
    elsif current_batch?
      flash[:notice] = flash_message('active_batch')
      redirect_to current_batch_path
    else
      @batch = BuildBatch.call(params[:batch], current_user)

      flash[:notice] = 'Batch created.'

      redirect_to root_path
    end
  end

  def current
    @batch = current_user.batches.where(active: true, batch_type: 0).first

    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      nil
    end
  end

  def remove
    if params[:match_id].present?
      match = Match.find(params[:match_id])
      remove_match(match: match) if match.present?
    end

    redirect_to current_batch_path
  end

  def retrieve
    @batch = current_user.batches.where(active: true, batch_type: 0).first

    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      return
    end

    @match = @batch.current_match

    if @match.nil? # then we're done processing matches
      redirect_to finalize_batch_path
      nil
    end
  end

  def item
    @batch = current_user.batches.where(active: true, batch_type: 0).first

    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      return
    end

    @match = Match.find(params[:match_id])

    if params[:commit] == 'Skip'
      @match.processed = 'skipped'
      @match.save!

      ActivityLogger.skip_item(item: @match.item, request: @match.request, user: current_user)

      redirect_to retrieve_batch_path
      nil
    else
      if params[:barcode] != @match.item.barcode
        flash[:error] = 'Wrong item scanned.'

        redirect_to retrieve_batch_path
        nil
      else
        flash[:notice] = "Item #{@match.item.barcode} scanned."
        ActivityLogger.accept_item(item: @match.item, request: @match.request, user: current_user)
        redirect_to bin_batch_path
        nil
      end

    end
  end

  def bin
    @batch = current_user.batches.where(active: true, batch_type: 0).first

    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      return
    end

    @match = @batch.current_match
  end

  def scan_bin
    @batch = current_user.batches.where(active: true, batch_type: 0).first
    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      return
    end

    @match = Match.find(params[:match_id])

    if params[:commit] == 'Skip'
      @match.processed = 'skipped'
      @match.save!

      ActivityLogger.skip_item(item: @match.item, request: @match.request, user: current_user)

      redirect_to retrieve_batch_path
      nil
    else
      barcode = params[:barcode]
      if !IsBinBarcode.call(barcode)
        flash[:error] = "#{barcode} is not a bin, please try again."
        redirect_to bin_batch_path
        nil
      else
        if BinType.call(barcode) != @match.request.bin_type
          flash[:error] = "#{barcode} is not the correct type, please try again."
          redirect_to bin_batch_path
          nil
        else # success!
          @bin = GetBinFromBarcode.call(barcode)
          @match.item.bin = @bin
          @match.item.save!
          @match.bin = @bin
          @match.save!
          ActivityLogger.associate_item_and_bin(item: @match.item, bin: @bin, user: current_user)

          UnstockItem.call(@match.item, current_user)

          AcceptMatch.call(@match)

          flash[:notice] = "Item #{@match.item.barcode} is now in bin #{barcode}."
          redirect_to retrieve_batch_path # on to the next item in the batch
          nil
        end
      end
    end
  end

  def finalize
    @batch = current_user.batches.where(active: true, batch_type: 0).first

    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      return
    end

    @matches = @batch.skipped_matches
  end

  def finish
    @batch = current_user.batches.where(active: true, batch_type: 0).first

    if @batch.blank?
      flash[:error] = "#{current_user.username} does not have an active batch, please create one."
      redirect_to batches_path
      return
    end

    FinishBatch.call(@batch, current_user)
    flash[:notice] = 'Finished processing batch, ready to begin a new batch.'
    redirect_to batches_path
  end

  def view_processed
    @batches = Batch.where(active: false)
  end

  def view_single_processed
    @batch = Batch.find(params[:id])
  end

  def view_active
    @batches = Batch.where(active: true, batch_type: 0)
  end

  def view_single_active
    @batch = Batch.find(params[:id])
  end

  def cancel_single_active
    CancelBatch.call(params[:batch_id])

    redirect_to view_active_batches_path
  end

  private

  def remove_match(match:)
    ActiveRecord::Base.transaction do
      DestroyMatch.call(match: match, user: current_user)
      DissociateItemFromBin.call(item: match.item, user: current_user)
      FinishBatch.call(match.batch, current_user)
    end
  end

  def flash_message(type)
    case type
    when 'active_batch'
      I18n.t('batches.status.active')
    when 'empty_batch'
      I18n.t('batches.status.empty_items')
    end
  end

  def batch_blank?
    if params[:batch].blank?
      true
    end
  end

  def current_batch?
    if current_user.batches.where(active: true, batch_type: 0).count >= 1
      true
    end
  end
end
