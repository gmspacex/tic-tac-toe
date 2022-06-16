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
        uint8 winner; // true: Player1, false: Player2
        uint8 filledBoard;
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
    event GameOver(uint256 indexed gameId, uint8 winner);

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
        require(
            game.player1 != msg.sender,
            "you can't join the game you created."
        );
        require(game.status == GameStatus.Waiting);
        game.player2 = msg.sender;
        game.status = GameStatus.Playing;

        // Update first players turn
        // addresses -> bytes32 -> uint -> some mathmatics with (block.timestamp, gameId) (sum or mul) % 2 => 0 | 1

        gameHistory[msg.sender].push(gameId);

        emit StartGame(gameId);
    }

    /**
     * @notice Place X/O
     * @dev only the player in his turn can call this function
     */
    function doMove(uint256 gameId, uint256 place) external {
        Game storage game = games[gameId];
        require(
            (game.turn ? game.player1 : game.player2) == msg.sender,
            'Caller is not the player'
        );
        require(game.status == GameStatus.Playing, "Can't move in this game");
        require(place < 9 && game.board[place] == 0, 'Invalid place');

        // Player1 : O(1), Player2 : X(2)
        game.board[place] = game.turn ? 1 : 2;
        game.turn = !game.turn;
        game.filledBoard++;

        // winner => true: player1, false: player2
        if (game.filledBoard > 5) {
            // 00, XXX
            (bool isGameOver, uint8 winner) = _checkGameOver(gameId);
            if (isGameOver) {
                game.winner = winner;
                game.status = GameStatus.GameOver;

                emit GameOver(gameId, winner);
            }
        }

        emit Move(gameId, !game.turn, place);
    }

    /**
     * @notice Internal function to check GameOver
     * @return isGameOver true: GameOver, false: Game is not over
     * @return winner 0: No winner, 1: Player1, 2: Player2
     */
    function _checkGameOver(uint256 gameId)
        internal
        view
        returns (bool, uint8)
    {
        Game memory game = games[gameId];

        for (uint256 i = 0; i < 8; i++) {
            uint256[] memory b = tests[i];
            if (
                game.board[b[0]] != 0 &&
                game.board[b[0]] == game.board[b[1]] &&
                game.board[b[0]] == game.board[b[2]]
            ) return (true, game.board[b[0]] == 1 ? 1 : 2);
        }
        if (game.filledBoard == 9) {
            return (true, 0);
        }
        return (false, 0);
    }

    /**
     * @notice External function to check GameOver
     * @return isGameOver true: GameOver, false: Game is not over
     * @return winner true: Player1, false: Player2
     */
    function checkGameOver(uint256 gameId) external view returns (bool, uint8) {
        return _checkGameOver(gameId);
    }
}
