require 'spec_helper'
require 'time'

describe NSDocument do

  before do

    DocumentRepository.clear
    d = NSDocument.new(title: 'Test', text: 'foo')
    @doc = DocumentRepository.create d

  end

  it 'can create and update a document t1' do

    e = DocumentRepository.first
    assert e.title == 'Test'

    e.title = 'Test2'
    DocumentRepository.update e
    f = DocumentRepository.first
    assert f.title == 'Test2'

  end

  it 'can set up its links["documents"] value from an array t2' do

    doc_list = [ { 'id' => 10, 'title' => 'EM'}, { 'id' => 20, 'title' => 'Bio'}]
    @doc.set_links_from_array('documents', doc_list)
    assert @doc.get_links('documents') == doc_list

  end

  it 'can set up its links["documents"] value from a json string t3' do

    doc_list = [ { 'id' => 11, 'title' => 'EMM'}, { 'id' => 22, 'title' => 'Biology'}]
    json_string = doc_list.to_json
    @doc.set_links_from_json('documents', json_string)
    assert @doc.get_links('documents') == doc_list

  end

  it 'can update a document from a full or partial json string (1) t4' do

    hash = { 'text' => 'This is a test'}
    json_str = hash.to_json

    @doc.update_from_json(json_str)
    assert @doc.text == hash['text']
    assert @doc.title == 'Test'

  end

  it 'can update a document from a full or partial json string (2) t5' do

    hash = { 'identifier' => 'foo_1'}
    hash['owner_id'] = 55
    hash['collection_id'] = 66
    hash['title'] = 'Intro to quantum mechanics'

    hash['viewed_at'] = Time.now.utc.iso8601
    hash['visit_count'] = 2

    hash['text'] = 'foo123'
    hash['rendered_text'] = 'foobar'

    hash['public'] = true

    hash['dict'] = {'favorite_flavor' => 'vanilla'}
    document_array = [ { 'id' => 10, 'title' => 'EM'}, { 'id' => 20, 'title' => 'Bio'} ]
    resource_array = [ { 'id' => 100, 'type' => 'image'}, { 'id' => 200, 'title' => 'Bio', 'type' => 'PDF'} ]
    hash['links'] = { 'documents' => document_array, 'resources' => resource_array}

    # hash['tags'] = 'physics, quantum'
    hash['kind'] = 'asciidoc'


    json_str = hash.to_json

    @doc.update_from_json(json_str)

    assert @doc.identifier == hash['identifier']
    assert @doc.owner_id == hash['owner_id']
    assert @doc.collection_id == hash['collection_id']

    assert @doc.title == hash['title']

    assert @doc.viewed_at == hash['viewed_at']
    assert @doc.visit_count == hash['visit_count']

    assert @doc.text == hash['text']
    assert @doc.rendered_text == hash['rendered_text']

    assert @doc.public == true

    assert @doc.dict['favorite_flavor'] == 'vanilla'
    assert @doc.links['documents'] == document_array
    assert @doc.links['resources'] == resource_array
    # assert @doc.tags == hash['tags']
    assert @doc.kind == hash['kind']

  end

 it 'can attach a child document and then detach it t6' do

   d = NSDocument.new(title: 'A', text: 'foo')
   a = DocumentRepository.create d

   d = NSDocument.new(title: 'B', text: 'bar')
   b = DocumentRepository.create d

   a.adopt_child b

   assert b.parent_name == a.title
   assert a.child_names == [b.title]

   a.remove_child b
   b.remove_parent

   assert b.parent_id == 0
   assert b.child_names == []

 end

  it 'can unlink a document t7' do

    d = NSDocument.new(title: 'A', text: 'top')
    a = DocumentRepository.create d

    d = NSDocument.new(title: 'B', text: 'middle')
    b = DocumentRepository.create d

    d = NSDocument.new(title: 'C', text: 'bottom')
    c = DocumentRepository.create d

    a.adopt_child b
    b.adopt_child c

    assert a.child_names == ['B']
    assert b.parent_name == 'A'

    assert b.child_names == ['C']
    assert c.parent_name == 'B'

    b.unlink

    a = DocumentRepository.find a.id
    b = DocumentRepository.find b.id
    c = DocumentRepository.find c.id

    assert a.child_names == []
    assert c.parent_name == ''

    assert b.parent_name == ''
    assert b.child_names == []


  end


  it 'can delete a document and cleanup after itself t8' do

    d = NSDocument.new(title: 'A', text: 'top')
    a = DocumentRepository.create d

    d = NSDocument.new(title: 'B', text: 'middle')
    b = DocumentRepository.create d

    d = NSDocument.new(title: 'C', text: 'bottom')
    c = DocumentRepository.create d

    a.adopt_child b
    b.adopt_child c

    assert a.child_names == ['B']
    assert b.parent_name == 'A'

    assert b.child_names == ['C']
    assert c.parent_name == 'B'

    bid = b.id

    NSDocument.delete b

    a = DocumentRepository.find a.id
    c = DocumentRepository.find c.id

    assert a.child_names == []
    assert c.parent_name == ''

    assert (DocumentRepository.find bid) == nil



  end



end
