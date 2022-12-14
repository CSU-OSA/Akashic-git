# frozen_string_literal: true

class Projects::Environments::SampleMetricsController < Projects::ApplicationController
  feature_category :metrics
  urgency :low

  def query
    result = Metrics::SampleMetricsService.new(params[:identifier], range_start: params[:start], range_end: params[:end]).query

    if result
      render json: { "status": "success", "data": { "resultType": "matrix", "result": result } }
    else
      render_404
    end
  end
end
