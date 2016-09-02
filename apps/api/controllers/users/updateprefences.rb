


module Api::Controllers::Users




  class Updateprefences
    include Api::Action

    def call(params)
      user = UserRepository.find_by_username params[:id]
      preferences = user.dict['preferences']
      preferences['doc_format'] = params['doc_format'] if( params['doc_format'] != nil && params['doc_format'] != '')
      user.dict['preferences'] = preferences
      UserRepository.update user
      self.body = {status: 'success', preferences: preferences}.to_json
    end
  end
end
