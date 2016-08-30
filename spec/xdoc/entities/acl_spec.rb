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

  it 'can remove an acl t2' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    assert acl.name == 'test'
    assert acl.members == []

    Acl.remove(acl.name)
    acl = AclRepository.find_by_name(acl.name)
    assert acl == nil

  end


  it 'can can add and remove new members to an acl' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add_member('joe')

    assert acl.members ==['joe']

    acl.add_member('sue')
    assert acl.members ==['joe', 'sue']

    assert acl.index_of_member('sue') == 1

    acl.remove_member('joe')
    assert acl.members ==['sue']

  end

  it 'can can determine whether the acl contains a given user' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add_member('joe')
    acl.add_member('sue')

    assert acl.contains_member('sue') == true
    assert acl.contains_member('john') == false

  end

  ####



  it 'can can add and remove new documents from/to an acl dd1' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add_document(22)

    assert acl.documents ==[22]

    acl.add_document(33)
    assert acl.documents ==[22,33]

    assert acl.index_of_document(22) == 0

    acl.remove_document(22)
    assert acl.documents ==[33]

  end

  it 'can can determine whether the acl contains a given user dd2' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add_document(22)
    acl.add_document(33)

    assert acl.contains_document(22) == true
    assert acl.contains_document(44) == false

  end

  ####

  it 'can can determine whether a user can edit a document' do

    acl = Acl.create(name: 'test', owner_id: 30, permission: 'edit')
    acl.add_member('joe')
    acl.add_member('sue')
    acl.add_document(22)

    assert acl.grants('sue', 22, 'edit') == true
    assert acl.grants('sue', 33, 'edit') == false
    assert acl.grants('john', 22, 'edit') == false

  end

  it 'can inspect and array of acls to determine if a user has permission for a document' do

    acl1 = Acl.create(name: 'abc', owner_id: 30, permission: 'edit')
    acl1.add_member('joe')
    acl1.add_member('sue')
    acl1.add_document(22)


    acl2 = Acl.create(name: 'def', owner_id: 30, permission: 'edit')
    acl2.add_member('fred')
    acl2.add_member('laura')
    acl2.add_document(33)

    acl_list = [acl1, acl2]

    assert Acl.grants('joe', 22, 'edit', acl_list) == true
    assert Acl.grants('frank', 22, 'edit', acl_list) == false

    assert Acl.grants('laura', 33, 'edit', acl_list) == true
    assert Acl.grants('joe', 33, 'edit', acl_list) == false

  end

  it 'can inspect the acl lists of a document to see whether a given user is granted permission for a given operation ttt' do


    acl1 = Acl.create(name: 'abc', owner_id: 30, permission: 'edit')
    acl1.add_member('joe')
    acl1.add_member('sue')
    acl1.add_document(22)


    acl2 = Acl.create(name: 'def', owner_id: 30, permission: 'edit')
    acl2.add_member('fred')
    acl2.add_member('laura')
    acl2.add_document(33)

    acl_list = [acl1, acl2]

    document = NSDocument.new(id: 33, title: 'test', dict: { acl: ['abc', 'def']})

    assert document.id == 33
    assert document.acl_lists == ['abc', 'def']



  end


end
