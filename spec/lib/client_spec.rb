require "spec_helper"

describe GContacts::Client do
  include Support::ResponseMock

  context "contact" do
    it "loads all" do
      mock_response(File.read("spec/responses/contacts/all.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/contacts/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234")
      contacts = client.all(:params => {"updated-min" => "1234"})

      contacts.id.should == "john.doe@gmail.com"
      contacts.updated.to_s.should == "2012-04-03T01:31:38+00:00"
      contacts.title.should == "Johnny's Contacts"
      contacts.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
      contacts.next_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=26&max-results=25")
      contacts.per_page.should == 25
      contacts.start_index.should == 1
      contacts.total_results.should == 4
      contacts.should have(4).items

      contact = contacts.first
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/908f380f4c2f81"
      contact.title.should == "Jack"
      contact.updated.to_s.should == "2011-07-27T00:35:14+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/908f380f4c2f81/6694635726310080")
      contact.data.should have(0).items

      contact = contacts[1]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/d7c3474a8da0bd"
      contact.title.should == "Steve Bar"
      contact.updated.to_s.should == "2012-02-06T01:14:56+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/d7c3474a8da0bd/7271189759352103")
      contact.data.should == {"gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.bar@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.bar@yahoo.com"}], "gd:phoneNumber" => [{"text" => "2004006000", "@rel" => "http://schemas.google.com/g/2005#mobile"}, {"text" => "2004005000", "@rel" => "http://schemas.google.com/g/2005#work"}]}

      contact = contacts[2]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/ec12328666b0d2"
      contact.title.should == "Joe Foo"
      contact.updated.to_s.should == "2011-06-29T23:11:57+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/ec12328666b0d2/2280001151204646")
      contact.data.should == {"gd:organization" => [{"gd:orgName" => "Joe's Real Estate", "@rel" => "http://schemas.google.com/g/2005#work"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "joe.foo@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "1003004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}]}

      contact = contacts[3]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/604e2ed2ae232b"
      contact.title.should == "Jane Doe"
      contact.updated.to_s.should == "2012-03-24T05:01:47+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/604e2ed2ae232b/9909171259275624")
      contact.data.should == {"gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "jane.doe@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "6502004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}], "gd:postalAddress" => [{"text" => "5 Market Street, San Francisco, CA", "@rel" => "http://schemas.google.com/g/2005#home"}]}
    end

    it "paginates through all" do
      request_uri = ["/m8/feeds/contacts/default/full", "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=3&max-results=2", "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=5&max-results=2"]
      request_uri.each_index do |i|
        res_mock = mock("Response#{i}")
        res_mock.stub(:body).and_return(File.read("spec/responses/contacts/paginate_all_#{i}.xml"))
        res_mock.stub(:code).and_return("200")
        res_mock.stub(:message).and_return("OK")
        res_mock.stub(:header).and_return({})

        http_mock = mock("HTTP#{i}")
        http_mock.should_receive(:use_ssl=).with(true)
        http_mock.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        http_mock.should_receive(:start)
        http_mock.should_receive(:request_get).with(request_uri[i], anything).and_return(res_mock)

        Net::HTTP.should_receive(:new).ordered.once.and_return(http_mock)
      end

      expected_titles = ["Jack 1", "Jack 2", "Jack 3", "Jack 4", "Jack 5"]

      client = GContacts::Client.new(:access_token => "12341234")
      client.paginate_all do |entry|
        entry.title.should == expected_titles.shift
      end

      expected_titles.should have(0).items
    end

    it "gets a single one" do
      mock_response(File.read("spec/responses/contacts/get.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/contacts/default/base/908f380f4c2f81?a=1", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234")
      element = client.get("908f380f4c2f81", :params => {:a => 1})

      element.should be_a_kind_of(GContacts::Element)
      element.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/908f380f4c2f81"
      element.title.should == "Dave Pratchett"
      element.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/908f380f4c2f81/6694635726310080")
    end
  end

  context "groups" do
    it "loads all" do
      mock_response(File.read("spec/responses/groups/all.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/groups/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      groups = client.all(:params => {"updated-min" => "1234"})

      groups.id.should == "john.doe@gmail.com"
      groups.updated.to_s.should == "2012-04-05T17:32:56+00:00"
      groups.title.should == "Johnny's Contact Groups"
      groups.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
      groups.next_uri.should be_nil
      groups.per_page.should == 25
      groups.start_index.should == 1
      groups.total_results.should == 2
      groups.should have(2).items

      group = groups.first
      group.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/908f380f4c2f81"
      group.title.should == "Family"
      group.updated.to_s.should == "2009-08-17T20:33:20+00:00"
      group.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/908f380f4c2f81/6694635726310080")
      group.data.should have(0).items

      group = groups[1]
      group.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/d7c3474a8da0bd"
      group.title.should == "Work"
      group.updated.to_s.should == "2009-07-23T07:37:59+00:00"
      group.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/d7c3474a8da0bd/7271189759352103")
      group.data.should have(0).items
    end

    it "paginates through all" do
      request_uri = ["/m8/feeds/groups/default/full", "/m8/feeds/groups/john.doe%40gmail.com/full?start-index=2&max-results=1"]
      request_uri.each_index do |i|
        res_mock = mock("Response#{i}")
        res_mock.stub(:body).and_return(File.read("spec/responses/groups/paginate_all_#{i}.xml"))
        res_mock.stub(:code).and_return("200")
        res_mock.stub(:message).and_return("OK")
        res_mock.stub(:header).and_return({})

        http_mock = mock("HTTP#{i}")
        http_mock.should_receive(:use_ssl=).with(true)
        http_mock.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        http_mock.should_receive(:start)
        http_mock.should_receive(:request_get).with(request_uri[i], anything).and_return(res_mock)

        Net::HTTP.should_receive(:new).ordered.once.and_return(http_mock)
      end

      expected_titles = ["Family", "Work"]

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      client.paginate_all do |entry|
        entry.title.should == expected_titles.shift
      end

      expected_titles.should have(0).items
    end

    it "gets a single one" do
      mock_response(File.read("spec/responses/groups/get.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/groups/default/base/908f380f4c2f81?a=1", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      element = client.get("908f380f4c2f81", :params => {:a => 1})

      element.should be_a_kind_of(GContacts::Element)
      element.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/d7c3474a8da0bd"
      element.title.should == "Work"
      element.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/d7c3474a8da0bd/7271189759352103")
    end
  end
end