# frozen_string_literal: true

class InstanceStatistics::CohortsController < InstanceStatistics::ApplicationController
  def index
    if Gitlab::CurrentSettings.usage_ping_enabled
      cohorts_results = Rails.cache.fetch('cohorts', expires_in: 1.day) do
        CohortsService.new.execute
      end

      @cohorts = CohortsSerializer.new.represent(cohorts_results)
    end
  end
end
