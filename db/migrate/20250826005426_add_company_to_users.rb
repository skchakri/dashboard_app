class AddCompanyToUsers < ActiveRecord::Migration[7.2]
  def up
    # First, create a default company for existing users
    default_company = Company.create!(name: "Default Company", subdomain: "default")
    
    # Add the column without null constraint first
    add_reference :users, :company, foreign_key: true
    
    # Update all existing users to belong to the default company
    User.update_all(company_id: default_company.id)
    
    # Now add the null constraint
    change_column_null :users, :company_id, false
  end

  def down
    remove_reference :users, :company, foreign_key: true
  end
end
