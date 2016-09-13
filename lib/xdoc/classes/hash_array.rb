require 'json'

module XDoc


  # A class for managing arrays of hashes.
  # E.G.:
  #   list = [ { 'id' => 10, 'title' => 'EM'}, { 'id' => 20, 'title' => 'Bio'}]
  #   oc = OrderedHashCollection.new(list)
  class HashArray

    def initialize(items = [], capacity = 1000 )
      @items = items
      @capacity = capacity
    end

    def set_capacity(capacity)
      @capacity = capacity
    end

    def capacity
      @capacity
    end

    def items
      @items
    end

    def to_json
      @items.to_json
    end

    def self.from_json(str)
      HashArray.new(JSON.parse(str))
    end

    def [](k)
      @items[k]
    end

    def first
      @items[0]
    end

    def last
      n = @items.count - 1
      @items[n]
    end

    def []= (k,value) # setter
      @items[k] = value
    end

    def push(item)
      if @items.count >= @capacity
        puts 'SHIFT'
        @items.shift
      end
      puts 'PUSH'
      @items.push(item)
    end

    def push_promote(item, attr)
      k = self.attribute_list(attr).index(item[attr])
      puts "push_unique: #{k}"
      if k == nil
        self.push(item)
      else
        self.swap(k,k+1) if k + 1 < @capacity
      end
      return k
    end

    def push_unique(item, attr)
      if !(self.attribute_list(attr).include? item[attr])
        self.push(item)
      end
    end

    def pop
      @items.pop
    end

    def shift
      @items.shift
    end

    def unshift(item)
      @items.unshift(item)  if @items.count < @capacity
    end

    def unshift_unique(item, attr)
      if !(self.attribute_list(attr).include? item[attr])
        @items.unshift(item)  if @items.count < @capacity
      end
    end

    def insert(k, item)
      @items.insert(k, item)  if @items.count < @capacity
    end

    def insert_unique(k, item, attr)
      if !(self.attribute_list(attr).include? item[attr])
        @items.insert(k, item)  if @items.count < @capacity
      end
    end

    def delete_at(k)
      @items.delete_at(k)
    end

    # move item j to position
    # before item k
    def move_before(j,k)
      if j < k
        x = @items.delete_at(j)
        @items.insert(k-1,x)
      end
      if j > k
        x = @items.delete_at(j)
        @items.insert(k,x)
      end
      @items
    end

    # move item j to position
    # after item k
    def move_after(j,k)
      if j < k
        x = @items.delete_at(j)
        @items.insert(k,x)
      end
      if j > k
        x = @items.delete_at(j)
        @items.insert(k+1,x)
      end
      @items
    end

    def swap(j,k)
      item = @items[j]
      @items[j] = @items[k]
      @items[k] = item
      @items
    end

    def count
      @items.count
    end

    # return list of values for the given attr
    # assuming that @items is an array of hashes,
    # e.g., [ { 'id': 10, 'title': 'EM'}, { 'id': 20, 'title': 'Bio'}]
    def attribute_list(attr)
      @items = @items.select{ |x| x != nil}
      @items.map { |x| x[attr] }
    end

    # get attr => value for @items[k]
    def self.attribute(attr, item)
      item[attr]
    end

    # set attr => value for @items[k]
    def set_attribute(k, attr, value)
      @items[k][attr] = value
    end


  end


end