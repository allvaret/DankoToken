// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
/// @title Danko Token
/// @author Alvaro Danko
/// @notice Esse contrato foi criado para fins educacionais, caso deseje realizar alguma implementação há medidas adicionais de segurança.  
/// @dev A documentação foi feita tanto pensado em outras pessoas entenderem o meu código como uma retomada de tudo que foi feito. Pretendo voltar neste projeto tentado reduzir alguns custos de gas quando tiver maior conhecimento sobre a linguagem.

// @notice EN - This contract was created for educational purposes, aiming to understand how the creation of a cryptocurrency works from the inside, as well as its small and painful development. (First contacts with solidity)
// @dev EN - The documentation was made both thinking about other people understanding my code as a resumption of everything that was done. I intend to return to this project trying to reduce some gas costs when I have greater knowledge about the language.

// Definição geral
interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function transfer(address to, uint256 transferAmount) external returns (bool);
    function approve(address spender, uint256 transferAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 transferAmount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 transferAmount);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 transferAmount);
    // As declarações: external, public, internal e private. Definem a visibilidade da função, cada uma tem uma utilização desejada no mundo real, como estamos em um
    // ambiente de testes, deixei todas em public e external. Elas representam, respectivamente que: Qualquer um pode acessar e não pode ser acessada internamente, ou pelo contrato em si.
    // View indica que a função é "only-read"
    // uint256 representa como iremos trabalhar com o retorno em bites, o U, indica que é um unsigned (Apenas números positivos) / INT inteiros e 256 é o tamanho em bits.
}


// Criação do contrato; informações bases
contract DankoToken is ERC20Interface {
    string public symbol = "DK";
    string public name = "Danko Coin";
    uint8 public decimals = 18;
    uint256 public _totalSupply;
    address public onlyOwner;

    mapping(address => uint256) public balances; // Público para testes mais fáceis
    mapping(address => mapping(address => uint256)) public allowed; 
    
// Construtor da moeda; Estamos definindo quantas criptos serão geradas. O require esta exigindo que, quem realiza a transação seja o mesmo que deu origem as transações.
    constructor() {
        onlyOwner = msg.sender;
        _totalSupply = 1000000 * 10**18; // Com decimais

        balances[msg.sender] = _totalSupply; // Manda o suply inicial para o endereço de lançamento.
        emit Transfer(address(0), msg.sender, _totalSupply); // o emit Transfer é um log de eventos, que pode ser usado off-chain
    }
    
// Este modificador serve para Atividades administrativas (permissão maior / sudo).
    modifier onlyAdmin() {
        require(msg.sender == onlyOwner, "Only owner can call this function");
        _; 
    }

    function totalSupply() public view override returns (uint256) { // Override (nesta utilização) seria a reescrita dos dados
        return _totalSupply;
    }

// Função para criar mais moedas
// OnlyAdmin é uma limitação de acesso, onde apenas o criador das moedas pode acessar.

    function mint(address to, uint256 amount) public onlyAdmin { 
        _totalSupply += amount;  // Poderiamos usar math library para evitar underflows e overflows, isso em qualquer operação do código
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

// Função para queimar moedas 
//      Requerimentos:
//      - O remetente deve ter um balance suficiente para queimar a quantidade especificada.

//      Emite um evento Transfer indicando a queima dos tokens.
//      @param amount A quantidade de tokens a serem queimados.
    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

/**
        Retorna o balance de tokens de um endereço especificado.
        @param tokenOwner O endereço para o qual o balance será retornado.
        @return O balance de tokens do endereço especificado.
         */
    function balanceOf(address tokenOwner) public view override returns (uint256) {
        return balances[tokenOwner];
    }

 /**
        Transfere uma quantidade especificada de tokens de um endereço para outro.
        Requerimentos:
        - O remetente (msg.sender) deve ter um balance suficiente para realizar a transferência.
        - O endereço de destino não pode ser o endereço zero.
        Emite um evento Transfer indicando a transferência dos tokens.
        @param to. O endereço para o qual os tokens serão transferidos.
        @param transferAmount. A quantidade de tokens a serem transferidos.
        @return true se a transferência foi bem sucedida, false caso contrário.
*/
    function transfer(address to, uint256 transferAmount) public override returns (bool) {
        require(transferAmount <= balances[msg.sender]);
        require(to != address(0), "Cannot transfer to zero address");

        balances[msg.sender] -= transferAmount;
        balances[to] += transferAmount;
        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }

/**
        Aprova um endereço especificado para gastar uma quantidade especificada de tokens do remetente.
        Emite um evento Approval indicando a aprovação.
        
        @param spender O endereço que será autorizado a gastar os tokens.
        @param transferAmount A quantidade de tokens que o spender pode gastar.
        @return true se a aprovação foi bem sucedida, false caso contrário.
        */
    function approve(address spender, uint256 transferAmount) public override returns (bool) {
        allowed[msg.sender][spender] = transferAmount;
        emit Approval(msg.sender, spender, transferAmount);
        return true;
    }

    /*
    Retorna a aprovação de um gastador.
    @param tokenOwner O endereço do detentor de tokens.
    @param spender O endereço do gastador.
    @return A aprovação do gastador.
    */

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    /**
    Transfere tokens de um endereço para outro em nome de um terceiro.
    @param from. O endereço de origem da transferência.
    @param to. O endereço de destino da transferência.
    @param transferAmount. A quantidade de tokens a transferir.
    @return True se a transferência foi bem-sucedida, false caso contrário.
     */
    function transferFrom(address from, address to, uint256 transferAmount) public override returns (bool) {
        require(transferAmount <= balances[from], "Insufficient balance");
        require(transferAmount <= allowed[from][msg.sender], "Insufficient allowance");
        require(to != address(0), "Cannot transfer to zero address");

        balances[from] -= transferAmount;
        allowed[from][msg.sender] -= transferAmount;
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
        return true;
    }

    /**
     * @dev Modificador para prevenir ataques de reentrada. || É recomendado o OpenZeppelin quando em criação, que possui um Reentrancy Guard.
     */
     modifier nonReentrant() {
        bool notEntered = true;
        require(notEntered, "ReentrancyGuard: reentrant call");
        notEntered = false;
        _;
        notEntered = true;
    }
}