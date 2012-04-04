module Support
  module ResponseMock
    def mock_response(body, method=:request_get)
      res_mock = mock("Response")
      res_mock.stub(:body).and_return(body)
      res_mock.stub(:code).and_return("200")
      res_mock.stub(:message).and_return("OK")
      res_mock.stub(:header).and_return({})

      http_mock = mock("HTTP")
      http_mock.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      http_mock.should_receive(:start)

      if block_given?
        yield http_mock, res_mock
      else
        http_mock.should_receive(method).with(any_args).and_return(res_mock)
      end

      Net::HTTP.should_receive(:new).and_return(http_mock)
    end
  end
end