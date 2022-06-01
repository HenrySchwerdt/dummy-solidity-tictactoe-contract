// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract TicTacToe {

    enum State {
        BIDDING,
        PLAYING,
        GAME_OVER
    }

    uint public bid;

    uint16 DRAW = 0x1FF;
    uint16 ROW_1 = 0x7;
    uint16 ROW_2 = 0x38;
    uint16 ROW_3 = 0x1C0;
    uint16 COLUMN_1 = 0x49;
    uint16 COLUMN_2 = 0x92;
    uint16 COLUMN_3 = 0x124;
    uint16 DIAGONAL_1 = 0x111;
    uint16 DIAGONAL_2 = 0x54;
  
    address payable playerA;
    address payable playerB; 
    address payable currentPlayer;   
    
    uint16 public boardA;
    uint16 public boardB;


    string public winner = "No winner yet";

    State public stage;

    // Payment Errors
    error FunctionInvalidAtThisStage();
    error WrongBidAmount();
    error NotPlayingAgainstDifferentPlayer();

    // Game Errors
    error FieldIsAlreadyInUse();
    error NotValidField();

    constructor() payable {
        playerA = payable(msg.sender);
        currentPlayer = playerA;
        boardA = 0;
        boardB = 0;
        bid = msg.value;
        stage = State.BIDDING;
    } 


    // Funding of Contract
    function buyIn() atStage(State.BIDDING) matchesBid isNotPlayerA payable public {
        playerB = payable(msg.sender);
        nextStage();
    }
    
    // Both parties pay the same amount
    modifier matchesBid() {
        if (msg.value < bid || msg.value > bid) {
            revert WrongBidAmount();
        }
        _;
    }
    
    // Cannot play against itself
    modifier isNotPlayerA() {
        if (playerA == payable(msg.sender)) {
            revert NotPlayingAgainstDifferentPlayer();
        }
        _;
    }
    
    // Is in the right stage
    modifier atStage(State _stage) {
        if (_stage != stage) {
            revert FunctionInvalidAtThisStage();
        }
        _;
    }

    // Playing TicTacToe
    function play(uint8 field) atStage(State.PLAYING) isVaildField(field) isFieldAlreadyInUse(field) public {
        setField(field);
        if(isDraw()) {
            playerA.transfer(bid);
            playerB.transfer(bid);
            winner = "DRAW";
        }
        if(isWinner(boardA)) {
            playerA.transfer(bid * 2);
            stage = State.GAME_OVER;
            winner = "Player A is winner!";
        }
        if(isWinner(boardB)) {
            playerB.transfer(bid * 2);
            stage = State.GAME_OVER;
            winner = "Player B is winner!";
        }
        switchPlayer();
    }


    // Utility

    function switchPlayer() internal {
        if (currentPlayer == playerA) {
            currentPlayer = playerB;
        } else {
            currentPlayer = playerA;
        }
    }

    function setField(uint8 field) internal {
        if (currentPlayer == playerA) {
            boardA = boardA | getPositon(field);
        }else {
            boardB = boardB | getPositon(field);
        }
    }

    function nextStage() internal {
        stage = State(uint(stage) + 1);
    }

    function mergeBoards() internal view returns(uint16) {
        return boardA | boardB;
    }

    function getPositon(uint8 field) internal pure returns(uint16) {
        return uint16(1 << field);
    }

    modifier isVaildField(uint8 field) {
        if (field >= 9) {
            revert NotValidField();
        }
        _;
    }

    modifier isFieldAlreadyInUse(uint8 field) {
        if (boardA & getPositon(field) > 0 ||
            boardB & getPositon(field) > 0) {
                revert FieldIsAlreadyInUse();
        }
        _;
    }

    function isDraw() view internal returns(bool){
        return mergeBoards() & DRAW == DRAW; 
    }

    function isWinner(uint16 board) internal view returns(bool) {
        return hasMatch(~board, ROW_1) || hasMatch(~board, ROW_2) ||
                hasMatch(~board, ROW_3) || hasMatch(~board, COLUMN_1) ||
                hasMatch(~board, COLUMN_2) || hasMatch(~board, COLUMN_3) ||
                hasMatch(~board, DIAGONAL_1) || hasMatch(~board, DIAGONAL_2);
    }

    function hasMatch(uint16 board1, uint16 board2) internal pure returns(bool) {
        return (board1 & board2) == 0;
    }

} 
