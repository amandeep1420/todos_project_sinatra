# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

# Helpers are available in both routes -and- view templates
# Define outside of helpers block if method is needed in routes only
helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end
  
  def list_class(list)
    "complete" if list_complete?(list)
  end
  
  def todos_count(list)
    list[:todos].size
  end
  
  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end
  
  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    
    incomplete_lists.each { |list| yield(list, lists.index(list)) }
    complete_lists.each { |list| yield(list, lists.index(list)) }
  end
  
  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }
    
    incomplete_todos.each { |todo| yield(todo, todos.index(todo)) }
    complete_todos.each { |todo| yield(todo, todos.index(todo)) }
  end
end

before do
  session[:lists] ||= []
end

def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list
  
  session[:error] = "The specified list was not found."
  redirect "/lists"
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# View an existing todo list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list    = load_list(@list_id)
  
  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  id    = params[:id].to_i
  @list = load_list(id)
  
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post '/lists/:id' do
  list_name = params[:list_name].strip
  error     = error_for_list_name(list_name)
  id        = params[:id].to_i
  @list     = load_list(id)
  
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name]      = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{id}"
  end
end

# Return an error message if the list name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

# Return an error message if the todo name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover?(name.size)
    'Todo name must be between 1 and 100 characters.'
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error     = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Delete a todo list
post '/lists/:id/delete' do
  lists = session[:lists]
  id    = params[:id].to_i
  
  lists.delete_at(id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:deleted] = "The list has been deleted."
    redirect "/lists"
  end
end

# Add a new todo to a todo list
post "/lists/:list_id/todos" do
  @list_id   = params[:list_id].to_i
  @list      = load_list(@list_id)
  text       = params[:todo].strip
  error      = error_for_todo(text)
  
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = 'The todo was added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a todo list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list    = load_list(@list_id)
  todos    = @list[:todos]
  todo_id  = params[:todo_id].to_i
  
  todos.delete_at(todo_id)
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:todo_id" do
  @list_id     = params[:list_id].to_i
  @list        = load_list(@list_id)
  todos        = @list[:todos]
  todo_id      = params[:todo_id].to_i
  is_completed = (params[:completed] == "true")
  
  todos[todo_id][:completed] = is_completed
  session[:success]          = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete
post "/lists/:id/complete_all" do
  @list_id     = params[:id].to_i
  @list        = load_list(@list_id)
  
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  
  session[:success] = "All todos have been completed."
  redirect "lists/#{@list_id}"
end


# Unused attempt
# post "/lists/:list_id/todos/:todo_id/complete" do
#   @list_id          = params[:list_id].to_i
#   @list             = session[:lists][@list_id]
#   todos             = @list[:todos]
#   todo_id           = params[:todo_id].to_i
#   updated_completion_status = (params[:completed] == 'true')
  
#   todos[todo_id][:completed] = updated_completion_status
#   redirect "/lists/#{@list_id}"
# end