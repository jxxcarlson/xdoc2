require 'spec_helper'



describe AclRepository do

  before do
    AclRepository.clear
  end

  it 'can retrieve an acl by name' do

    acl = Acl.new(name: 'test', owner_id: 30, permission: 'edit')
    AclRepository.create acl

    acl= AclRepository.find_by_name 'test'
    assert acl.name == 'test'

    acl2 = AclRepository.find_by_name 'foo'
    assert acl2.must_be_nil

  end

end
