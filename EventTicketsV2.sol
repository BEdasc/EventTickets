pragma solidity >=0.5.0 < 0.7.0;

    /*
    The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
    */
contract EventTicketsV2 {

    address payable public owner;
    uint   PRICE_TICKET = 100 wei;
    uint public idGenerator;

    /*
    The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
    The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping(address => uint) buyers;
        bool isOpen; 
    }
    
    /*
        Mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Just the owner can call this function");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    /* Fallback function - Called if other functions don't match
    Added so ether sent to this contract is reverted if the contract fails
    otherwise, the sender's money is transferred to contract
    */
    function()
    external
    payable
    {
        revert("Something goes wrong!");
    }

    function addEvent(string memory _description, string memory _website, uint _totalTickets)
    public
    onlyOwner
    returns(uint eventId)
    {
        uint eventId;
        eventId ++;

        events[eventId] = Event ({
        description : _description,
        website : _website,
        totalTickets : _totalTickets,
        sales : 0,
        isOpen : true
        });
        emit LogEventAdded(_description, _website, _totalTickets, eventId);
        return(eventId);
    }

    function readEvent(uint eventId)
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        Event storage myEvent = events[eventId];
        return (
            myEvent.description,
            myEvent.website,
            myEvent.totalTickets,
            myEvent.sales,
            myEvent.isOpen
        );
    }

    function buyTickets(uint eventId, uint ticketsToBePurchased)
    public
    payable
    {
        Event storage myEvent = events[eventId];
        
        require(myEvent.isOpen == true, "Event is not open!");
        require(msg.value >= ticketsToBePurchased*PRICE_TICKET, "Not enough funds to buy tickets");
        require(myEvent.totalTickets - myEvent.sales >= ticketsToBePurchased, "Not enough tickets available!");
        myEvent.sales += ticketsToBePurchased;
        myEvent.buyers[msg.sender] += ticketsToBePurchased;
        myEvent.totalTickets -= ticketsToBePurchased;
        uint priceToPay = ticketsToBePurchased*PRICE_TICKET;
        msg.sender.transfer(msg.value - priceToPay);
        owner.transfer(priceToPay);
        emit LogBuyTickets(msg.sender, eventId, ticketsToBePurchased);
    }

function getRefund(uint eventId)
        public
        payable
        {
            Event storage myEvent = events[eventId];
            
            require(myEvent.buyers[msg.sender] > 0, "No tickets purchased registrered!");
            uint ticketsToRefund = myEvent.buyers[msg.sender];
            myEvent.totalTickets += ticketsToRefund;
            myEvent.sales -= ticketsToRefund;
            myEvent.buyers[msg.sender] = 0; //avoid multi refund
            msg.sender.transfer(ticketsToRefund*PRICE_TICKET);
            emit LogGetRefund (msg.sender, eventId, ticketsToRefund);

        }
   
    function getBuyerNumberTickets(uint eventId)
    public
    view
    returns(uint ticketsPurchased)
    {
      Event storage myEvent = events[eventId];
      ticketsPurchased = myEvent.buyers[msg.sender];
      return(ticketsPurchased);
    }

    function endSale(uint eventId)
    public
    onlyOwner
    {
        Event storage myEvent = events[eventId];
        myEvent.isOpen = false;
        owner.transfer(address(this).balance);
        emit LogEndSale(owner, address(this).balance, eventId);

    }
}
