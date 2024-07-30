Rails.application.routes.draw do
  namespace :foreman_opennebula do
    match 'hosts/vmgroup_selected', :to => 'hosts#vmgroup_selected', :via => 'post'
    match 'hosts/scheduler_hint_filter_selected', :to => 'hosts#scheduler_hint_filter_selected', :via => 'post'
  end
end
