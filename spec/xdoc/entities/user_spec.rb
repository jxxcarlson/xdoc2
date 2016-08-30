require 'spec_helper'

require_relative '../../../lib/xdoc/interactors/create_user'

describe CreateUser do

  before do

    UserRepository.clear

  end

  it 'can create a user t1' do

    user = User.new(username: 'johndoe')
    UserRepository.create user
    user2 = UserRepository.first
    assert user2.username == 'johndoe'

  end


  it 'can create a user t1b' do

    user = User.new(username: 'johndoe', email: 'doe@foo.io', password: 'hohoho', admin: true, status: 'ok')
    UserRepository.create user
    user2 = UserRepository.first
    assert user2.username == 'johndoe'
    assert user2.email == 'doe@foo.io'
    # assert user2.password == 'hohoho'
    assert user2.admin == true
    assert user2.dict == {}
    assert user2.links == {}

  end

  it 'can update a user t2' do

    user = User.new(username: 'johndoe')
    UserRepository.create user
    user2 = UserRepository.first
    assert user2.username == 'johndoe'


    user2.dict['likes'] = 23
    UserRepository.update user2


  end

  it 'can create a user and set a password t3' do

    user = User.new(username: 'johndoe')
    UserRepository.create user
    user = UserRepository.first
    user.change_password('foobar1234')
    # UserRepository.update user
    assert user.username == 'johndoe'
    assert user.verify_password('foobar1234') == true
    assert user.verify_password('foobar123') == false

  end

  it 'can set preferences for a user t4' do

    user = User.new(username: 'johndoe')
    UserRepository.create user
    user = UserRepository.first
    user.set_preference('doc_format', 'asciidoc-latex')
    assert user.get_preference('doc_format') == 'asciidoc-latex'

  end

end
