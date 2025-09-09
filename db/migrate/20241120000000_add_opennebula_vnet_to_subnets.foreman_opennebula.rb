class AddOpennebulaVnetToSubnets < ActiveRecord::Migration[6.1]
  def change
    add_column :subnets, :opennebula_vnet, :integer, null: true
  end
end
