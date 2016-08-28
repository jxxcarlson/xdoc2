require 'spec_helper'


require_relative '../../../lib/xdoc/interactors/acl_manager'

describe ACLManager do

  before do
    AclRepository.clear
  end

  it 'can parse a command t1' do

    commands = ACLManager.new('create_acl=fred&permission=edit', 1).call.commands
    assert commands == [['create_acl', 'fred'], ['permission', 'edit']]

    commands = ACLManager.new('create_acl=fred', 1).call.commands
    assert commands == [['create_acl', 'fred']]

    commands = ACLManager.new('', 1).call.commands
    assert commands == []

  end

  it 'can create and remove acl t2' do

    result = ACLManager.new('create_acl=fred&permission=edit', 1).call
    assert result.status == 'success'
    acl = AclRepository.find_by_name 'fred'
    assert acl.name == 'fred'
    assert acl.permission == 'edit'
    assert acl.owner_id == 1

    result = ACLManager.new('remove_acl=fred', 1).call
    assert result.status == 'success'
    acl = AclRepository.find_by_name 'fred'
    puts "acl: #{acl.inspect}"
    assert acl == nil


  end


  it 'can create and remove a user from/to an acl t3' do

    ACLManager.new('create_acl=newsroom&permission=edit', 1).call
    ACLManager.new('add_user=john&acl=newsroom', 1).call
    result = ACLManager.new('add_user=sue&acl=newsroom', 1).call
    assert result.status == 'success'
    acl = AclRepository.find_by_name 'newsroom'
    assert acl.members.include? 'john'
    assert acl.members.include? 'sue'

    ACLManager.new('remove_user=john&acl=newsroom', 1).call
    acl = AclRepository.find_by_name 'newsroom'
    assert acl.members.include?('john') == false
    assert acl.members.count == 1

    ACLManager.new('remove_user=sue&acl=newsroom', 1).call
    acl = AclRepository.find_by_name 'newsroom'
    assert acl.members.include?('sue') == false
    assert acl.members.count == 0

  end


  it 'can create and remove a document from/to an acl t4' do

    ACLManager.new('create_acl=newsroom&permission=edit', 1).call
    ACLManager.new('add_document=22&acl=newsroom', 1).call
    ACLManager.new('add_document=33&acl=newsroom', 1).call
    result = ACLManager.new('add_user=sue&acl=newsroom', 1).call
    assert result.status == 'success'
    acl = AclRepository.find_by_name 'newsroom'
    assert acl.documents.include? 22
    assert !(acl.documents.include? 44)

    ACLManager.new('remove_document=22&acl=newsroom', 1).call
    acl = AclRepository.find_by_name 'newsroom'
    assert acl.documents.include?(22) == false
    assert acl.documents.count == 1


  end

  it 'can grant or reject a user request to operate on a document t5' do

    ACLManager.new('create_acl=newsroom&permission=edit', 1).call
    ACLManager.new('add_document=22&acl=newsroom', 1).call
    ACLManager.new('add_document=33&acl=newsroom', 1).call
    ACLManager.new('add_user=sue&acl=newsroom', 1).call

    result = ACLManager.new('request_permission=edit&acl=newsroom&document=22&user=sue', 1).call
    assert result.status == 'success'


  end

end
