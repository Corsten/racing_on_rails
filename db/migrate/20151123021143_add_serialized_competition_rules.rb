class AddSerializedCompetitionRules < ActiveRecord::Migration
  def change
    change_table :events, force: true do |t|
      t.text :place_bonus
    end

    reversible do |m|
      m.up do
        transaction do
          (Competitions::MbraBar.all + Competitions::MbraTeamBar.all).each do |c|
            c.place_bonus = [ 6, 3, 1 ]
            c.save!
          end
        end
      end
    end
  end
end
