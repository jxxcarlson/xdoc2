require 'spec_helper'

describe Acl do

  before do
    AclRepository.clear
  end

  it 'can create an acl' do


    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    assert acl.name == 'test'
    assert acl.members == []

  end


  it 'can can add and remove new members to an acl' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add('joe')

    assert acl.members ==['joe']

    acl.add('sue')
    assert acl.members ==['joe', 'sue']

    assert acl.index_of('sue') == 1

    acl.remove('joe')
    assert acl.members ==['sue']

  end

  it 'can can determine whether the acl contains a given user' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add('joe')
    acl.add('sue')

    assert acl.contains('sue') == true
    assert acl.contains('john') == false

  end

  it 'can can determine whether a user can edit a document' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add('joe')
    acl.add('sue')

    assert acl.grants('sue', 'edit') == true
    assert acl.grants('john','edit') == false

  end

  it 'can inspect and array of acls to determine if a user has permission' do

    acl1 = Acl.create(name: 'abc', owner_id: 30, permission: 'edit')
    acl1.add('joe')
    acl1.add('sue')


    acl2 = Acl.create(name: 'def', owner_id: 30, permission: 'edit')
    acl2.add('fred')
    acl2.add('laura')

    acl_list = [acl1, acl2]

    assert Acl.grants('fred', 'edit', acl_list) == true
    assert Acl.grants('joe', 'edit', acl_list) == true
    assert Acl.grants('larry', 'edit', acl_list) == false

  end


end
