require "spec_helper"

describe GContacts::Client::Contact do
  include Support::ResponseMock

  it "loads all contacts" do
    mock_response(File.read("spec/responses/contacts/all.xml")) do |http_mock, res_mock|
      http_mock.should_receive(:request_get).with("/m8/feeds/contacts/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
    end

    contacts = GContacts::Client::Contact.new(:access_token => "12341234").all(:params => {"updated-min" => "1234"})

    contacts.id.should == "john.doe@gmail.com"
    contacts.updated.to_s.should == "2012-04-03T01:31:38+00:00"
    contacts.title.should == "Johnny's Contacts"
    contacts.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
    contacts.next_uri.should == "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=26&max-results=25"
    contacts.per_page.should == 25
    contacts.start_index.should == 1
    contacts.total_results.should == 4
    contacts.should have(4).items

    contact = contacts.first
    contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/908f380f4c2f81"
    contact.title.should == "Jack"
    contact.updated.to_s.should == "2011-07-27T00:35:14+00:00"
    contact.edit_uri.should == "/m8/feeds/contacts/john.doe%40gmail.com/full/908f380f4c2f81/6694635726310080"
    contact.data.should have(0).items

    contact = contacts[1]
    contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/d7c3474a8da0bd"
    contact.title.should == "Steve Bar"
    contact.updated.to_s.should == "2012-02-06T01:14:56+00:00"
    contact.edit_uri.should == "/m8/feeds/contacts/john.doe%40gmail.com/full/d7c3474a8da0bd/7271189759352103"
    contact.data.should == {"gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.bar@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.bar@yahoo.com"}], "gd:phoneNumber" => [{"text" => "2004006000", "@rel" => "http://schemas.google.com/g/2005#mobile"}, {"text" => "2004005000", "@rel" => "http://schemas.google.com/g/2005#work"}]}

    contact = contacts[2]
    contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/ec12328666b0d2"
    contact.title.should == "Joe Foo"
    contact.updated.to_s.should == "2011-06-29T23:11:57+00:00"
    contact.edit_uri.should == "/m8/feeds/contacts/john.doe%40gmail.com/full/ec12328666b0d2/2280001151204646"
    contact.data.should == {"gd:organization" => [{"gd:orgName" => "Joe's Real Estate", "@rel" => "http://schemas.google.com/g/2005#work"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "joe.foo@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "1003004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}]}

    contact = contacts[3]
    contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/604e2ed2ae232b"
    contact.title.should == "Jane Doe"
    contact.updated.to_s.should == "2012-03-24T05:01:47+00:00"
    contact.edit_uri.should == "/m8/feeds/contacts/john.doe%40gmail.com/full/604e2ed2ae232b/9909171259275624"
    contact.data.should == {"gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "jane.doe@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "6502004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}], "gd:postalAddress" => [{"text" => "5 Market Street, San Francisco, CA", "@rel" => "http://schemas.google.com/g/2005#home"}]}
  end
end