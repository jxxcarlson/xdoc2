require 'spec_helper'


require_relative '../../../lib/xdoc/interactors/acl_manager'

describe ACLManager do

  it 'can parse a command t1' do

    commands = ACLManager.new('create_acl=fred&permission=edit').call.commands
    assert commands == [['create_acl', 'fred'], ['permission', 'edit']]

    commands = ACLManager.new('create_acl=fred').call.commands
    assert commands == [['create_acl', 'fred']]

    commands = ACLManager.new('').call.commands
    assert commands == []

  end

  it 'can recognize seven commands t2' do

    result = ACLManager.new('create_acl=fred&permission=edit').call
    assert result.status == 'success'

    result = ACLManager.new('remove_acl=fred&permission=edit').call
    assert result.status == 'success'

    result = ACLManager.new('add_user=fred&ack=baz.readings').call
    assert result.status == 'success'

    result = ACLManager.new('remove_user=fred&ack=baz.readings').call
    assert result.status == 'success'

    result = ACLManager.new('add_document=17&acl=baz.readings').call
    assert result.status == 'success'

    result = ACLManager.new('remove_document=17&acl=baz.readings').call
    assert result.status == 'success'

    result = ACLManager.new('request_permission=edit&document=17&user=joe').call
    assert result.status == 'success'

    result = ACLManager.new('mess_it_all_up=yes').call
    assert result.status == 'error'

  end

end
