class TraysController < ApplicationController
  def index
    @tray = Tray.new
  end

  def scan
    begin
      @tray = Tray.where(barcode: params[:tray][:barcode]).first_or_create!
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.message
      redirect_to trays_path
      return
    end
    redirect_to show_tray_path(:id => @tray.id)
  end

  def show
    @tray = Tray.find(params[:id])
  end

  def associate
    @tray = Tray.find(params[:id])

    barcode = params[:barcode]

    if BarcodeProcessor.call(@tray, barcode)
      redirect_to show_tray_path(:id => @tray.id)
      return
    else
      raise "unable to process barcode"
    end

    redirect_to show_tray_path(:id => @tray.id)
    return
  end

  # The only reason to get here is to set the tray's shelf to nil, so let's do that.
  def dissociate
    @tray = Tray.find(params[:id])

    if DissociateTray.call(@tray)
      redirect_to show_tray_path(:id => @tray.id)
    else
      raise "unable to dissociate tray"
    end
  end
end
