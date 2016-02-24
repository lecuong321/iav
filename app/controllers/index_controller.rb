require 'httparty'
require 'rest_client'
class IndexController < ApplicationController

  helper_method :form, :responses

  def form
    @form
  end

  def responses
    @responses
  end

  def index
    if session[:cobSessionToken]
      render 'main'
    else
      redirect_to '/coblogin'
    end
  end

  def coblogin
    if (params[:base_url])
      session[:cobSessionToken] = 1

      @form = Yodlee::Config.send(params[:function])
      session[:base_url] = params[:base_url]
      Yodlee::Services.base_uri session[:base_url]
      session[:fastLinkUrl] = params[:fastlink_url]
      opts = {
        :endpoint => @form['endpoint'],
        :method => @form['method'],
        :params => params
      }
      response = Yodlee::Services.new.query(opts)
      if (response.has_key?('cobrandConversationCredentials') && response.cobrandConversationCredentials.has_key?('sessionToken'))
        session[:cobSessionToken] = response.cobrandConversationCredentials.sessionToken
        render 'register'
      else
        render 'login'
      end
    else
      render 'login'
    end
  end

  def register
    render 'register'
  end

  def doRegister
    # url = 'https://developer.api.yodlee.com/ysl/restserver/v1/user/register'
    # requestBody = {"user"=> {
    #   'loginName' => params[:username],
    #   'password' => params[:password],
    #   'email' => params[:email],
    #   'name' => {'first'=>params[:fname], 'last'=>params[:lname]},
    #   'address' => {'address1'=>'200 Lincoln Ave', 'state'=> 'CA', 'city'=> 'Salinas', 'zip'=> '93901', 'country'=> 'USA'},
    #   'preferences' => { 'currency'=> 'USD','timeZone'=> 'PST', 'dateFormat'=> 'MM/dd/yyyy'}}
    # }
    # #raise requestHeader.to_json
    # requestHeader = {:authorization => 'cobSession='+session[:cobSessionToken]+'', :registerParam => requestBody.to_json}
    # res = RestClient.post url, requestBody.to_json, requestHeader
    # response = JSON.parse(res.body)
    # raise response.inspect
    session[:register] = true
    render 'main'
  end

  def login
    @form = Yodlee::Config.send(params[:function])
    Yodlee::Services.base_uri session[:base_url]
    opts = {
      :endpoint => @form['endpoint'],
      :method => @form['method'],
      :params => params
    }

    response = Yodlee::Services.new.query(opts)

    session[:response] = response.to_json
    if response.userContext && response.userContext.conversationCredentials && response.userContext.conversationCredentials.sessionToken
      session[:userSessionToken] = response.userContext.conversationCredentials.sessionToken
    end
    redirect_to root_url
  end

  def window
    @finAppId = 10003620
    session[:finAppId] = @finAppId
    @url = session[:fastLinkUrl]
    @userToken = session[:userSessionToken]
    @fastLinkToken = getFastLinkToken()
  end

  def getFastLinkToken
    params[:function] = 'getFastLinkToken'
    params[:cobSessionToken] = session[:cobSessionToken]
    params[:rsession] = session[:userSessionToken]
    params[:finAppId] = session[:finAppId]
    @form = Yodlee::Config.send(params[:function])
    Yodlee::Services.base_uri session[:base_url]
    opts = {
      :endpoint => @form['endpoint'],
      :method => @form['method'],
      :params => params
    }

    response = Yodlee::Services.new.query(opts)

    return response.finappAuthenticationInfos[0].token
  end

  def getAccounts
    @banks = getBanks()
    if @banks.present?
      session[:emptyBank] = false
      render 'accounts'
    else
      session[:emptyBank] = true
      render 'main'
    end
  end

  def getBanks
    requestHeader = {:authorization => 'cobSession='+session[:cobSessionToken]+',userSession='+session[:userSessionToken]+''}
    url = 'https://developer.api.yodlee.com/ysl/restserver/v1/accounts'
    res = RestClient.get url, requestHeader
    return JSON.parse(res.body)
  end

  def hyperWallet
    @banks = getBanks()
    users = getHyperWalletUsers()
    @currentUser = users[2]
    @transferMethods = getHyperWalletTransferMethods()
    if (session[:createHyperWallet].nil?)
      @banks['account'].each do |account|
        createTransferMethods = createHyperWalletTransferMethod(account)
        payment = createHyperWalletPayment(account)
      end
      session[:createHyperWallet] = true
    end
    @transferMethods = getHyperWalletTransferMethods()
    @payments = getHyperWalletPayments()
    render 'hyper-wallet'
  end

  def convert_to_mash data
    if data.is_a? Hash
      Hashie::Mash.new(data)
    elsif data.is_a? Array
      data.map { |d| Hashie::Mash.new(d) }
    end
  end

  def getHyperWalletUsers
    # Hyper Wallet configure
    @clientUserId = "IS3533440057"
    @programToken = "prg-0397d581-f35e-4888-b5fe-7d1698241201"
    @auth = {:username => "restapiuser@3533440057", :password => "P4ssW0rD"}

    response = HTTParty.get('https://uat.paylution.com/rest/v3/users?limit=25',
      basic_auth: @auth,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    data = response.parsed_response
    data = convert_to_mash(data)
    return data.data
  end

  def createHyperWalletTransferMethod account
    transferMethodCountry = 'CA'
    transferMethodCurrency = 'CAD'
    bankId = '001'
    branchId = '00011'

    lastTransferMethod =  @transferMethods.last
    bankAccountId = lastTransferMethod.bankAccountId.to_i + 1

    data = {
      type: "BANK_ACCOUNT",
      transferMethodCountry: transferMethodCountry,
      transferMethodCurrency: transferMethodCurrency,
      bankId: bankId,
      branchId: branchId,
      bankAccountId: bankAccountId
    }

    response = HTTParty.post('https://uat.paylution.com/rest/v3/users/' + @currentUser.token + '/transfer-methods',
      body: data.to_json,
      basic_auth: @auth,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    return response.parsed_response
  end

  def getHyperWalletTransferMethods
    response = HTTParty.get('https://uat.paylution.com/rest/v3/users/' + @currentUser.token + '/transfer-methods',
      basic_auth: @auth,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    data = response.parsed_response
    data = convert_to_mash(data)
    return data.data
  end

  def createHyperWalletPayment account
    amount = account['balance']['amount']
    currency = account['balance']['currency']
    description = 'Description'
    memo = 'PmtBatch-20150501'
    purpose = 'PP0013'

    data = {
      amount: amount,
      currency: currency,
      description: description,
      memo: memo,
      purpose: purpose,
      destinationToken: @currentUser.token,
      programToken: @programToken
    }

    response = HTTParty.post('https://uat.paylution.com/rest/v3/payments/',
      body: data.to_json,
      basic_auth: @auth,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    return response.parsed_response
  end

  def getHyperWalletPayments
    response = HTTParty.get('https://uat.paylution.com/rest/v3/payments?limit=25',
      basic_auth: @auth,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    )

    data = response.parsed_response
    data = convert_to_mash(data)
    return data.data
  end

  def destroy
    reset_session
    redirect_to root_url
  end

  def reset
    session[:userSessionToken] = nil
    redirect_to root_url
  end

  def service
    @form = Yodlee::Config.send(params[:function])
    @form[:function] = params[:function]
    @form['params']['cobSessionToken'] = session[:cobSessionToken] if @form['params'].has_key?('cobSessionToken')
    @form['params']['userSessionToken'] = session[:userSessionToken] if @form['params'].has_key?('userSessionToken')
    #if (params[:action])
      Yodlee::Services.base_uri session[:base_url]
      opts = {
        :endpoint => @form['endpoint'],
        :method => @form['method'],
        :params => params
      }
      @responses = Yodlee::Services.new.query(opts).to_json
    #else
    #  @responses = nil
    #end
    render 'main'
  end

  def flow
    services = {
      "data" => [
        "getContentServiceInfoByRoutingNumber",
        "getContentServiceInfo1",
        "getLoginFormForContentService",
        "addItemAndStartVerificationDataRequest",
        "getMFAResponse",
        "putMFARequest",
        "getItemVerificationData"],
      "matching" => [
        "getContentServiceInfoByRoutingNumber",
        "getContentServiceInfo1",
        "getLoginFormForContentService",
        "addItemForContentService1",
        "addTransferAccountForItem",
        "getVerifiableAccount",
        "startVerificationWithMFA1",
        "getMFAResponse",
        "putMFARequest",
        "getVerificationInfo1",
        "getMatchingAccountVerificationData"
      ]
    }
    @form = []
    session[:logs] = [] if session[:logs].nil?
    session[:logs] = [] if params[:step].to_i == 0
    for i in 0..params[:step].to_i
      function = services[params[:service]][i]
      _form = Yodlee::Config.send(function)
      _form['params']['cobSessionToken'] = session[:cobSessionToken] if _form['params'].has_key?('cobSessionToken')
      _form['params']['userSessionToken'] = session[:userSessionToken] if _form['params'].has_key?('userSessionToken')
      if i < params[:step].to_i
        _form['class'] = 'flow disabled'
        _form['disabled'] = true
      else
        _form['class'] = 'flow'
        _form['disabled'] = false
      end
      _form[:function] = function

      if i == params[:step].to_i
        @form << _form
      end
    end

    if (params[:submit])
      function = services[params[:service]][params[:step].to_i]
      _form = Yodlee::Config.send(function)

      Yodlee::Services.base_uri session[:base_url]
      opts = {
        :endpoint => _form['endpoint'],
        :method => _form['method'],
        :params => params
      }
      @responses = Yodlee::Services.new.query(opts)
      log = {
        :index => session[:logs].length,
        :endpoint => _form['endpoint'],
        :response => @responses.to_json
      }
      session[:logs] << log
      if !@responses.has_key?('errorOccurred')
        if params[:step].to_i < (services[params[:service]].length - 1)
          params[:step] = params[:step].to_i + 1
          redirect_to '/flow/'+params[:service]+'/'+ params[:step].to_s
        else
          render 'service'
        end
      else
        render 'service'
      end
    else
      render 'service'
    end
  end
end
