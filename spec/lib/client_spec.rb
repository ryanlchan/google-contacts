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
      contacts.updated.to_s.should == "2012-04-05T21:46:31+00:00"
      contacts.title.should == "Johnny's Contacts"
      contacts.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
      contacts.next_uri.should be_nil
      contacts.per_page.should == 25
      contacts.start_index.should == 1
      contacts.total_results.should == 4
      contacts.should have(4).items

      contact = contacts.first
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/fd8fb1a55f2916e"
      contact.title.should == "Steve Stephson"
      contact.updated.to_s.should == "2012-02-06T01:14:56+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/fd8fb1a55f2916e")
      contact.etag.should == "OWUxNWM4MTEzZjEyZTVjZTQ1Mjgy."
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Steve Stephson", "gd:givenName" => "Steve", "gd:familyName" => "Stephson"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.stephson@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve@gmail.com"}], "gd:phoneNumber" => [{"text" => "3005004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}, {"text" => "+130020003000", "@rel" => "http://schemas.google.com/g/2005#work"}]}

      contact = contacts[1]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/894bc75ebb5187d"
      contact.title.should == "Jill Doe"
      contact.updated.to_s.should == "2011-07-01T18:08:32+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/894bc75ebb5187d")
      contact.etag.should == "ZGRhYjVhMTNkMmFhNzJjMzEyY2Ux."
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Jill Doe", "gd:givenName" => "Jill", "gd:familyName" => "Doe"}]}

      contact = contacts[2]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/cd046ed518f0fb0"
      contact.title.should == 'Dave "Terry" Pratchett'
      contact.updated.to_s.should == "2011-06-29T23:11:57+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/cd046ed518f0fb0")
      contact.etag.should == "ZWVhMDQ0MWI0MWM0YTJkM2MzY2Zh."
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Dave \"Terry\" Pratchett", "gd:givenName" => "Dave", "gd:additionalName" => "\"Terry\"", "gd:familyName" => "Pratchett"}], "gd:organization" => [{"gd:orgName" => "Foo Bar Inc", "@rel" => "http://schemas.google.com/g/2005#work"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "dave.pratchett@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "7003002000", "@rel" => "http://schemas.google.com/g/2005#mobile"}]}

      contact = contacts[3]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/a1941d3d13cdc66"
      contact.title.should == "Jane Doe"
      contact.updated.to_s.should == "2012-04-04T02:08:37+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/a1941d3d13cdc66")
      contact.etag.should == "Yzg3MTNiODJlMTRlZjZjN2EyOGRm."
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Jane Doe", "gd:givenName" => "Jane", "gd:familyName" => "Doe"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "jane.doe@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "16004003000", "@rel" => "http://schemas.google.com/g/2005#mobile"}], "gd:structuredPostalAddress" => [{"gd:formattedAddress" => "5 Market St\n        San Francisco\n        CA\n      ", "gd:street" => "5 Market St", "gd:city" => "San Francisco", "gd:region" => "CA", "@rel" => "http://schemas.google.com/g/2005#home"}]}
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
      element.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8"
      element.title.should == "Casey"
      element.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8")
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
      groups.updated.to_s.should == "2012-04-05T22:32:03+00:00"
      groups.title.should == "Johnny's Contact Groups"
      groups.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
      groups.next_uri.should be_nil
      groups.per_page.should == 25
      groups.start_index.should == 1
      groups.total_results.should == 2
      groups.should have(2).items

      group = groups.first
      group.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"
      group.title.should == "System Group: My Contacts"
      group.updated.to_s.should == "1970-01-01T00:00:00+00:00"
      group.edit_uri.should be_nil
      group.etag.should == "YWJmYzA."
      group.data.should have(0).items

      group = groups[1]
      group.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/ada43d293fdb9b1"
      group.title.should == "Misc"
      group.updated.to_s.should == "2009-08-17T20:33:20+00:00"
      group.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/ada43d293fdb9b1")
      group.etag.should == "QXc8cDVSLyt7I2A9WxNTFUkLRQQ."
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

      expected_titles = ["Misc 1", "Misc 2"]

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
      element.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"
      element.title.should == "System Group: My Contacts"
      element.edit_uri.should be_nil
      element.etag.should == "YWJmYzA."
    end
  end
end