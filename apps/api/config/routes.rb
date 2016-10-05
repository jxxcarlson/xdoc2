get '/exportlatex/:id', to: 'documents#export_latex'
get '/useracl/:username', to: 'users#acl'
get '/hotlist/:username', to: 'users#hotlist'
post'/manage_users', to: 'users#manage'

post '/checkout', to: 'documents#checkout'
post '/update_preferences/:id', to: 'users#updateprefences'
get '/get_preferences/:id', to: 'users#getprefences'
post '/backup', to: 'documents#backup'
post '/acl', to: 'documents#acl'
post '/images/:id', to: 'images#update'
get '/printdocument/:id', to: 'documents#print'
get '/test', to: 'test#echo'


### UPLOAD
post '/presigned', to: 'upload#psurl'

### IMAGES
###
post '/images', to: 'images#create'
get '/images', to: 'images#find'
get '/images/:id', to: 'images#get'


### DOCUMENTS
###
get '/documents', to: 'documents#find'             # find documents, return array of hashes
post '/documents', to: 'documents#create'          # create document from json payload
get '/documents/:id', to: 'documents#read'         # read document - get json payload
post '/documents/:id', to: 'documents#update'      # update document from json payload
delete '/documents/:id', to: 'documents#delete'    # delete document


### USERS
###
### References:
###
###    http://restcookbook.com/Basics/loggingin/
###
# get /users/joe?foo123 = authenticate user joe with password foo123 and return token
get '/users/:id', to: 'users#gettoken'
# post /users= create user joe with password foo123 and return token
post '/users/create', to: 'users#create'


# Configure your routes here
# See: http://www.rubydoc.info/gems/hanami-router/#Usage