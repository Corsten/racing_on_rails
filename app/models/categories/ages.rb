module Categories
  module Ages
    extend ActiveSupport::Concern

    included do
      before_save :set_ages_from_name
    end

    def age_group?
      ages_begin && ages_end && (ages_begin != 0 || ages_end != ::Categories::MAXIMUM)
    end

    def and_over?
      ages_end && ages_end == ::Categories::MAXIMUM
    end

    def junior?
      age_group? && ages_end <= 18
    end

    def masters?
      age_group? && ages_begin >= 30
    end

    def senior?
      age_group? && ages == 19..29
    end

    # Return Range
    def ages
      ages_begin..ages_end
    end

    # Accepts an age Range like 10..18, or a String like 10-18
    def ages=(value)
      case value
      when Range
        self.ages_begin = value.begin
        self.ages_end = value.end
      else
        age_split = value.strip.split('-')
        self.ages_begin = age_split[0].to_i unless age_split[0].nil?
        self.ages_end = age_split[1].to_i unless age_split[1].nil?
      end
    end

    def set_ages_from_name
      if ages_begin.nil? || ages_begin == 0
        self.ages = ages_from_name(name)
      end
      ages
    end

    def ages_from_name(name)
      if name["+"]
        (name[/(\d\d)\+/].to_i)..::Categories::MAXIMUM
      elsif /(\d\d)-(\d\d)/.match(name)
        age_range_match = /(\d\d)-(\d\d)/.match(name)
        age_range_match[1].to_i..age_range_match[2].to_i
      elsif name["Junior"]
        10..18
      elsif name["Master"]
        30..::Categories::MAXIMUM
      elsif name[/U\d\d/]
        0..(/U(\d\d)/.match(name)[1].to_i - 1)
      else
        0..::Categories::MAXIMUM
      end
    end
  end
end
