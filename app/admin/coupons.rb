ActiveAdmin.register Coupon do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :coupon_code, :one_use, :creator_id, :interval
  #
  # or
  #
  # permit_params do
  #   permitted = [:coupon_code, :one_use, :creator_id, :interval, :coupon_bulk_generation]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :coupon_code
      f.input :one_use
      f.input :creator_id
      f.input :interval
      if f.object.new_record?
        f.li "<label for='coupon_bulk_generation' class='custom-checkbox'><input type='checkbox' name='coupon[bulk_generation]' id='coupon_bulk_generation' value='1' class='custom-input-checkbox'>Bulk generation</label>".html_safe
        f.li "<label class='label' for='coupon_quantity'>Number of codes to generate</label><input id='coupon_quantity' name='coupon[quantity]' type='number' min=0 max=1000 value=0>".html_safe
      end
    end
    actions
  end

  controller do
    def create
      if params[:coupon].present? && params[:coupon][:bulk_generation] == '1' && params[:coupon][:quantity].to_i > 0 && params[:coupon][:interval].present?
        params[:quantity] = params[:coupon][:quantity].to_i
        params[:interval] = params[:coupon][:interval]
        current_user.email = 'cj@vctry.gg'
        begin
          resp = current_user.voucher_to(params)
          CouponMailer.coupon_mail(current_user, resp, params[:interval]).deliver!
        rescue Exception => e
          Raven.capture_exception(e)
        end
        redirect_to admin_coupons_path
      else
        super
      end
    end
  end
end
