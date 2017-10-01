pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;

	uint numberBet;
	uint oracleBet;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
	    require(msg.sender == owner);
	    _;
	}
	modifier OracleOnly() {
	    require(msg.sender == oracle);
		_;
	}
	modifier betMax() {
		revert();
		_;
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
	    owner = msg.sender;
		outcomes = _outcomes;
	}


	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
	    oracle = _oracle;
		return oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
	    assert(numberBet < 2);
		assert(owner != msg.sender);
		if (numberBet == 0) {
			gamblerA = msg.sender;
			bets[gamblerA].outcome = _outcome;
			bets[gamblerA].amount = msg.value;
			bets[gamblerA].initialized = true;
			BetMade(gamblerA);
			}
		if (numberBet == 1) {
			gamblerB = msg.sender;
			bets[gamblerB].outcome = _outcome;
			bets[gamblerB].amount = msg.value;
			bets[gamblerB].initialized = true;
			BetMade(gamblerB);
		}
		numberBet += 1;
		if (numberBet == 2) {
			BetClosed();
		}
		return bets[msg.sender].initialized;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		assert(numberBet == 2);
	    oracleBet = _outcome;
		if (bets[gamblerA].outcome == bets[gamblerB].outcome) {
			gamblerA.transfer(bets[gamblerA].amount);
			gamblerB.transfer(bets[gamblerB].amount);
		} else if (bets[gamblerA].outcome == _outcome && bets[gamblerB].outcome != _outcome) {
		    winnings[gamblerA] += bets[gamblerB].amount;
		} else if (bets[gamblerA].outcome != _outcome && bets[gamblerB].outcome == _outcome) {
			winnings[gamblerB] += bets[gamblerA].amount;
		} else {
			oracle.transfer(bets[gamblerA].amount + bets[gamblerB].amount);
		}
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
	    uint amount = winnings[msg.sender];
		if (amount > withdrawAmount) {
			winnings[msg.sender] -= withdrawAmount;
			msg.sender.transfer(withdrawAmount);
		}
		remainingBal = winnings[msg.sender];
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
	    return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
	    return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
	    numberBet = 0;
	}

	/* Fallback function */
	function() {
		revert();
	}
}
