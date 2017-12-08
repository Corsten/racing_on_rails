module Categories
  module Equipment
    extend ActiveSupport::Concern

    included do
      before_save :set_equipment_from_name
    end

    def set_equipment_from_name
      self.equipment = equipment_from_name
    end

    # Relies on normalized name
    def equipment_from_name
      if name[/Singlespeed/]
        "Singlespeed"
      else
        name[/Eddy|Fat Bike|Hardtail|Merckx|Stampede|Tandem|Unicycle/]
      end
    end

    def equipment?
      equipment.present?
    end
  end
end
