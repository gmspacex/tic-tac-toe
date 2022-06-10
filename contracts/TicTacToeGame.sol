// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title Tic-Tac-Toe On-chain game
 * @author gmspacex
 * @notice Supports multiple sessions/players
 */
contract TicTacToeGame is Ownable {
    /// @dev Game Status
    enum GameStatus {
        NotHosted,
        Waiting,
        Playing,
        GameOver
    }

    /// @dev Game Info
    struct Game {
        GameStatus status;
        bool turn; // true: Player1, false: Player2
        bool winner; // true: Player1, false: Player2
        uint8[9] board; // 3x3 board => 0: Empty, 1: O, 2: X
        address player1;
        address player2;
    }

    uint256 gameIndex;

    /// @dev gameId => Game
    mapping(uint256 => Game) games;

    /// @dev player => gameIds
    mapping(address => uint256[]) gameHistory;

    /// @dev game over cases
    // 0 1 2
    // 3 4 5
    // 6 7 8
    uint256[][] tests = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6]
    ];

    event HostGame(uint256 indexed gameId, address player1);
    event StartGame(uint256 indexed gameId);
    event Move(uint256 indexed gameId, bool turn, uint256 place);
    event GameOver(uint256 indexed gameId, bool winner);

    /// @dev Modifier to limit access to players in right turn
    modifier onlyPlayer(uint256 gameId) {
        Game memory game = games[gameId];
        require(
            (game.turn ? game.player1 : game.player2) == msg.sender,
            'Caller is not the player'
        );
        _;
    }

    constructor() {}

    /**
     * @notice Create a new game
     * @dev set game status to Waiting
     */
    function createGame() external {
        Game storage newGame = games[gameIndex];
        newGame.status = GameStatus.Waiting;
        newGame.turn = true;
        newGame.player1 = msg.sender;

        gameHistory[msg.sender].push(gameIndex);

        emit HostGame(gameIndex, msg.sender);
        gameIndex++;
    }

    /**
     * @notice Join hosted game
     * @dev set game status to started
     */
    function joinGame(uint256 gameId) external {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Waiting);
        game.player2 = msg.sender;
        game.status = GameStatus.Playing;

        gameHistory[msg.sender].push(gameId);

        emit StartGame(gameId);
    }

    /**
     * @notice Place X/O
     * @dev only the player in his turn can call this function
     */
    function doMove(uint256 gameId, uint256 place) external onlyPlayer(gameId) {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Playing, "Can't move in this game");
        require(place < 9 && game.board[place] == 0, 'Invalid place');

        // Player1 : O(1), Player2 : X(2)
        game.board[place] = game.turn ? 1 : 2;
        game.turn = !game.turn;

        (bool isGameOver, bool winner) = _checkGameOver(gameId);
        if (isGameOver) {
            game.winner = winner;
            game.status = GameStatus.GameOver;

            emit GameOver(gameId, winner);
        }

        emit Move(gameId, !game.turn, place);
    }

    /**
     * @notice Internal function to check GameOver
     * @return isGameOver true: GameOver, false: Game is not over
     * @return winner true: Player1, false: Player2
     */
    function _checkGameOver(uint256 gameId) internal view returns (bool, bool) {
        Game memory game = games[gameId];
        for (uint256 i = 0; i < 8; i++) {
            uint256[] memory b = tests[i];
            if (
                game.board[b[0]] != 0 &&
                game.board[b[0]] == game.board[b[1]] &&
                game.board[b[0]] == game.board[b[2]]
            ) return (true, game.board[b[0]] == 1);
        }
        return (false, false);
    }

    /**
     * @notice External function to check GameOver
     * @return isGameOver true: GameOver, false: Game is not over
     * @return winner true: Player1, false: Player2
     */
    function checkGameOver(uint256 gameId) external view returns (bool, bool) {
        return _checkGameOver(gameId);
    }
}
