from brownie import network,accounts,config,MockV3Aggregator,Contract,VRFCoordinatorMock,LinkToken,interface
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ['development','ganache-local']
FORKED_LOCAL_ENVIRONMENTS=['mainnet-fork','mainnet-fork-dev']

def get_account(index=None,id=None):
    # accounts[0]
    # accounts.add(.env)
    # accounts.load('id')
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS or  network.show_active() in FORKED_LOCAL_ENVIRONMENTS :
        return accounts[0]

    return accounts.add(config["wallets"]["from_key"])

contract_to_mock = {"eth_usd_price_feed":MockV3Aggregator,
                    "vrf_coordinator":VRFCoordinatorMock,
                    "link_token":LinkToken}

def get_contract(contract_name):
    """this function will grab the contract addresses from the brownie config if defined, otherwise,
    it will deploy a mock version of that contract ,and return that mock contracts
    Arg:
        contract_name(string)
    Returns:
        brownie.network.contract.Projectcontract:the most recently deployed version of this contract.
    """
    contract_type = contract_to_mock[contract_name]

    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        if len(contract_type)<=0:
            print("need to deploy mocks")
        # MockV3Aggregator.length
            deploy_mocks()
        contract = contract_type[-1]
        #MockV3Aggregator[-1]
    else:
        contract_address = config['networks'][network.show_active()][contract_name]
        # address
        # abi
        contract =Contract.from_abi(contract_type._name,contract_address,contract_type.abi)
        #MockV3Aggregator.abi
    return contract 

DECIMALS=8
STARTING_PRICE=200000000000
def deploy_mocks(decimal=DECIMALS,starting_price=STARTING_PRICE):
    MockV3Aggregator.deploy(decimal,starting_price,{"from":get_account()})
    link_token=LinkToken.deploy({"from":get_account()})
    VRFCoordinatorMock.deploy(link_token.address,{"from":get_account()})
    print("mocks deployed")

def fund_with_link(contract_address,account=None,link_token=None,amount=100000000000000000):#0.1 LINK
    account=account if account else get_account()
    link_token=link_token if link_token else get_contract("link_token")
    tx=link_token.transfer(contract_address,amount,{"from":account})
    # link_token_contract=interface.LinkTokenInterface(link_token.address)
    # tx=link_token_contract.transfer(contract_address,amount,{"from":account})
    tx.wait(1)
    print("fund the contract")
    return tx
