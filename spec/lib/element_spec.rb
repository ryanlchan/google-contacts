require "spec_helper"

describe GContacts::Element do
  it "changes modifier flags" do
    element = GContacts::Element.new

    element.create
    element.modifier_flag.should == :create

    element.delete
    element.modifier_flag.should == nil

    element.instance_variable_set(:@edit_uri, URI("http://google.com"))
    element.update
    element.modifier_flag.should == :update

    element.delete
    element.modifier_flag.should == :delete
  end

  context "converts back to xml" do
    before :each do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")
    end

    it "with deleting an entry" do
      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element.delete

      element.to_xml.should == <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='YzllYTBkNmQwOWRlZGY1YWEyYWI5.'>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8</id>
</entry>
XML

      element.to_xml(true).should == <<XML
<entry gd:etag='YzllYTBkNmQwOWRlZGY1YWEyYWI5.'>
  <batch:id>delete</batch:id>
  <batch:operation type='delete'/>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8</id>
</entry>
XML
end

    it "with creating an entry" do
      element = GContacts::Element.new
      element.category = "contact"
      element.content = "Foo Content"
      element.title = "Foo Title"
      element.data = {"gd:name" => {"gd:fullName" => "John Doe", "gd:givenName" => "John", "gd:familyName" => "Doe"}}
      element.create

      element.to_xml.should == <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'>Foo Content</content>
  <title>Foo Title</title>
  <gd:name>
    <gd:fullName>John Doe</gd:fullName>
    <gd:givenName>John</gd:givenName>
    <gd:familyName>Doe</gd:familyName>
  </gd:name>
</entry>
XML

      element.to_xml(true).should == <<XML
<entry>
  <batch:id>create</batch:id>
  <batch:operation type='create'/>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'>Foo Content</content>
  <title>Foo Title</title>
  <gd:name>
    <gd:fullName>John Doe</gd:fullName>
    <gd:givenName>John</gd:givenName>
    <gd:familyName>Doe</gd:familyName>
  </gd:name>
</entry>
XML

    end

    it "updating an entry in batch" do
      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element.update

      element.to_xml.should == <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='YzllYTBkNmQwOWRlZGY1YWEyYWI5.'>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Casey</title>
  <gd:name>
    <gd:fullName>Casey</gd:fullName>
    <gd:givenName>Casey</gd:givenName>
  </gd:name>
  <gd:email rel='http://schemas.google.com/g/2005#other' address='casey@gmail.com' primary='true'/>
</entry>
XML

      element.to_xml(true).should == <<XML
<entry gd:etag='YzllYTBkNmQwOWRlZGY1YWEyYWI5.'>
  <batch:id>update</batch:id>
  <batch:operation type='update'/>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Casey</title>
  <gd:name>
    <gd:fullName>Casey</gd:fullName>
    <gd:givenName>Casey</gd:givenName>
  </gd:name>
  <gd:email/>
</entry>
XML
    end

    it "with contacts" do
      elements = GContacts::List.new(Nori.parse(File.read("spec/responses/contacts/all.xml")))

      expected_xml = []
      xml = <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='OWUxNWM4MTEzZjEyZTVjZTQ1Mjgy.'>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/fd8fb1a55f2916e</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Steve Stephson</title>
  <gd:name>
    <gd:fullName>Steve Stephson</gd:fullName>
    <gd:givenName>Steve</gd:givenName>
    <gd:familyName>Stephson</gd:familyName>
  </gd:name>
  <gd:email rel='http://schemas.google.com/g/2005#other' address='steve.stephson@gmail.com' primary='true'/>
  <gd:email rel='http://schemas.google.com/g/2005#other' address='steve@gmail.com'/>
  <gd:phoneNumber rel='http://schemas.google.com/g/2005#mobile'>3005004000</gd:phoneNumber>
  <gd:phoneNumber rel='http://schemas.google.com/g/2005#work'>+130020003000</gd:phoneNumber>
</entry>
XML
      expected_xml.push(xml)

      xml = <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='ZGRhYjVhMTNkMmFhNzJjMzEyY2Ux.'>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/894bc75ebb5187d</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Jill Doe</title>
  <gd:name>
    <gd:fullName>Jill Doe</gd:fullName>
    <gd:givenName>Jill</gd:givenName>
    <gd:familyName>Doe</gd:familyName>
  </gd:name>
</entry>
XML
      expected_xml.push(xml)


      xml = <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='ZWVhMDQ0MWI0MWM0YTJkM2MzY2Zh.'>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/cd046ed518f0fb0</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Dave "Terry" Pratchett</title>
  <gd:name>
    <gd:fullName>Dave "Terry" Pratchett</gd:fullName>
    <gd:givenName>Dave</gd:givenName>
    <gd:additionalName>"Terry"</gd:additionalName>
    <gd:familyName>Pratchett</gd:familyName>
  </gd:name>
  <gd:organization rel='http://schemas.google.com/g/2005#work'>
    <gd:orgName>Foo Bar Inc</gd:orgName>
  </gd:organization>
  <gd:email rel='http://schemas.google.com/g/2005#home' address='dave.pratchett@gmail.com' primary='true'/>
  <gd:phoneNumber rel='http://schemas.google.com/g/2005#mobile'>7003002000</gd:phoneNumber>
</entry>
XML
      expected_xml.push(xml)

      xml = <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='Yzg3MTNiODJlMTRlZjZjN2EyOGRm.'>
  <id>http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/a1941d3d13cdc66</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#contact'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Jane Doe</title>
  <gd:name>
    <gd:fullName>Jane Doe</gd:fullName>
    <gd:givenName>Jane</gd:givenName>
    <gd:familyName>Doe</gd:familyName>
  </gd:name>
  <gd:email rel='http://schemas.google.com/g/2005#home' address='jane.doe@gmail.com' primary='true'/>
  <gd:phoneNumber rel='http://schemas.google.com/g/2005#mobile'>16004003000</gd:phoneNumber>
  <gd:structuredPostalAddress rel='http://schemas.google.com/g/2005#home'>
    <gd:formattedAddress>5 Market St
        San Francisco
        CA
      </gd:formattedAddress>
    <gd:street>5 Market St</gd:street>
    <gd:city>San Francisco</gd:city>
    <gd:region>CA</gd:region>
  </gd:structuredPostalAddress>
</entry>
XML
      expected_xml.push(xml)

      elements.each do |element|
        element.to_xml.should == expected_xml.shift
      end

      expected_xml.should have(0).items
    end

    it "with groups" do
      elements = GContacts::List.new(Nori.parse(File.read("spec/responses/groups/all.xml")))

      expected_xml = []
      xml = <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='YWJmYzA.'>
  <id>http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>System Group: My Contacts</title>
</entry>
XML
      expected_xml.push(xml)

      xml = <<XML
<?xml version='1.0' encoding='UTF-8'?>
<entry gd:etag='QXc8cDVSLyt7I2A9WxNTFUkLRQQ.'>
  <id>http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/ada43d293fdb9b1</id>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008#'/>
  <updated>2012-04-06T06:02:04Z</updated>
  <content type='text'></content>
  <title>Misc</title>
</entry>
XML
      expected_xml.push(xml)

      elements.each do |element|
        element.to_xml.should == expected_xml.shift
      end

      expected_xml.should have(0).items
    end
  end
end