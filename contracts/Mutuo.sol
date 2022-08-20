// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;
pragma abicoder v2;


import { ERC20 } from "./solmate/ERC20.sol";
import { ERC721 } from "./solmate/ERC721.sol";
import { Owned } from "./solmate/Owned.sol";
import { SafeTransferLib } from "./solmate/SafeTransferLib.sol";


contract InvestStartup is ERC721, Owned(msg.sender) {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error TotalCaptureMade();
    error NotAcceptfromBothAddresses();
    error OutofTime();
    error Morethanthestartupneeds();
    error OnlyMutuante();
    error OnlyMutuario();
    error OnlyAuthorized();
    error GreaterThanNegotiated();
    error OnlyafterInvestmentFunding();
    error paused();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event FundsWithdrawn();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    address payable immutable ownerOmnes;

    //startup
    struct Mutuario {
        string nameStartup;
        uint256 cnpj;
        bool captation; //captação total alcançada
        uint256 minValue; //valor minimo
        uint256 targetValue;
        uint256 investedAmount;
        ERC20 quotas;
        uint256 numInvest;
        address payable mutuario;
    } //endereço que vai chamar na função que vai pagar

    mapping(address => Mutuario) public mutuarios;

    //Investidor
    struct Mutuante {
        string nome;
        uint64 cnpjoucpf;
        uint256 numInvestment;
        address payable mutuante;
        bool lookingFor;
    }

    mapping(address => Mutuante) public mutuantes;

    //definições do investimeto lançadas pela startup com o valor minimo e máximo
    struct startInvestment {
        uint256 value; //valor aceito
        uint256 finalTimeInvest;
        bool acceptStartup; //aceite da startup
        bool acceptInvestor; //aceite da empresa
    }
    mapping(address => mapping(address => startInvestment)) public whoInvWhatStartup;

    mapping(address => uint256) public timeforAccept;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    uint256 public totalInvestment;
    uint256 public numStartups;
    uint256 public numInvestors;
    uint256 initContract;
    uint256 public DURATION = 0; //aprox 2 years 730 days
    uint256 public timmeAccpet = 48 hours; //48 horas para aceitar
    bool pause;
    //permissions e termination

    mapping(address => bool) public authorizedAddress;
    mapping(address => bool) public authorizedQuota;

    //modifiers

    modifier pausedcontract(){
        if(!pause)revert paused();
        _;
    }

    modifier onlyMutuante() {
        if (msg.sender != mutuantes[msg.sender].mutuante) revert OnlyMutuante();
        _;
    }

    modifier onlyMutuario() {
        if (msg.sender != mutuarios[msg.sender].mutuario) revert OnlyMutuario();
        _;
    }

    modifier onlyAuthorized() {
        if (!authorizedAddress[msg.sender]) revert OnlyAuthorized();
        _;
    }

    modifier authorizeWithdrawalQuotas() {
        if (!authorizedQuota[msg.sender]) revert OnlyAuthorized();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() ERC721("Omnes-Mutuo", "OMBm") {
        ownerOmnes = payable(msg.sender);
        initContract = block.timestamp;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmWCbaw4vp4m6QKqrkxtQe7A7tsir9WGMgVvZaagMzSe9W";
    }
    //private
    function tokenQ() private view returns (ERC20 quota) {
        return mutuarios[msg.sender].quotas;
    }

    /// -----------------------------------------------------------------------
    /// externals and registers e authorization
    /// -----------------------------------------------------------------------

    //quantidade de tokens que vc tem no contrato
    function balanceOfcontractQuotas() external view returns (uint256) {
        return tokenQ().balanceOf(address(this));
    }

    //autorizar retirada de quotas como garantia
    function authorizewhidrawQuotas(address _startup, bool _authorization) external onlyOwner {
        authorizedQuota[_startup] = _authorization;
    }

    //autorizando ou desutorizando endereço, caso haja alguma infração favor desabilitar a autorização
    function authorizeDisallowAddress(address _startupOrInvestor, bool _authorization)
        external
        onlyOwner
        returns (string memory, address)
    {
        authorizedAddress[_startupOrInvestor] = _authorization;
        return (
            "the address authorized or unauthorized of the startup or registered investor is:",
            _startupOrInvestor
        );
    }

    function registerMutuante(string memory _nome, uint64 _cnpjoucpf) external onlyAuthorized {
        mutuantes[msg.sender] = Mutuante(_nome, _cnpjoucpf, 0, payable(msg.sender), true);
        unchecked {
            numInvestors++;
        }
    }

    function IdontWanttoInvest() external onlyAuthorized {
        require(msg.sender == mutuantes[msg.sender].mutuante, "you are not a Mutuante");
        mutuantes[msg.sender].lookingFor = false;
    }

    //vai mandar sempre 10 tokens que representam 10% das quotas da empresa como garantia
    function registerMutuario(
        string memory _nameStartup,
        uint256 _cnpj,
        uint256 _targetValue,
        ERC20 _quotas,
        uint256 _minValue
    ) external onlyAuthorized {
        require(_targetValue <= 10000000000000000000, "the target cannot exceed 10 ether");
        require(_minValue >= 1000000000000000000, "minimum value cannot be less 1 ether");
        mutuarios[msg.sender] = Mutuario(
            _nameStartup,
            _cnpj,
            false,
            _minValue,
            _targetValue,
            0,
            _quotas,
            0,
            payable(msg.sender)
        );
        unchecked {
            numStartups++;
        }
        //para transferir ele vai precisar ter os tokens na wallet
        //vai ficar na custódia do contrato 10% como garantia
        //antes aprovar no contrato token nos testes
        tokenQ().safeTransferFrom(msg.sender, address(this), 10);
    }

    //o investidor quer investir em uma determinada startup e estipulando o valor
    function InvestorWantsToInvest(address _startup, uint256 _value) external onlyMutuante {
        whoInvWhatStartup[msg.sender][_startup] = startInvestment(_value, 0, false, true);
        timeforAccept[_startup] = block.timestamp;
    }

    //only mutuaria Startup que executa e tempo começou quando o investidor sugeriu
    function accepetStartupInvestor(address _investor) external onlyMutuario {
        if (timeforAccept[msg.sender] + timmeAccpet <= block.timestamp) revert OutofTime();
        whoInvWhatStartup[_investor][msg.sender].acceptStartup = true;
    }

    //tem que ser do endereço certo na hora do accept
    function checkAccepts(address _investor, address _startup) external view returns (bool, bool) {
        return (
            whoInvWhatStartup[_investor][_startup].acceptInvestor,
            whoInvWhatStartup[_investor][_startup].acceptStartup
        );
    }

    /// -----------------------------------------------------------------------
    /// Investment and Pay Investment
    /// -----------------------------------------------------------------------

    function Invest(address _startup,uint _iddoc) external payable returns (bool sucess) {
        //se o valor de captação já foi atingido revert
        //require(mutuarios[msg.sender].targetValue <= msg.value, "value exceeds what the startup needs");
        //inserir depois ===>
        if (mutuarios[_startup].captation != false) revert TotalCaptureMade();
        //o valor inserido deve ser igual ao acordado entre a negociação
        require(
            whoInvWhatStartup[msg.sender][_startup].value == msg.value,
            "value must be the same as agreed"
        );
        //se o aceite do investidor ou da startup estiver negativa revert que não foi aceito a proposta ainda
        if (
            !whoInvWhatStartup[msg.sender][_startup].acceptInvestor ||
            !whoInvWhatStartup[msg.sender][_startup].acceptStartup
        ) revert NotAcceptfromBothAddresses();
        whoInvWhatStartup[msg.sender][_startup].finalTimeInvest = block.timestamp + DURATION;

        //atualização dos dados da struct investimento e referente ao mutuante
        unchecked {
            mutuantes[msg.sender].numInvestment++;
            //atualização mutuário:
            mutuarios[_startup].numInvest++;
            mutuarios[_startup].targetValue -= msg.value;
            //atualização do total de todas as rodadas
            mutuarios[_startup].investedAmount += msg.value;
            //atualização do valor total de todas as empresas
            totalInvestment += msg.value;

            //se o valor alvo chegar a zero a captação será concluida
            if (mutuarios[_startup].targetValue == 0) {
                mutuarios[_startup].captation = true;
            }
        }

        //distribuição dos percentuais
        uint256 feeOmnes = (msg.value * 10) / 1000; //1% para a Omnes
        uint256 smartcontractvalue = (msg.value * 49) / 100; //49% contrato
        uint256 firstInvestment = (msg.value * 50) / 100; //50% para a conta direto da Startup
        payable(ownerOmnes).transfer(feeOmnes);
        payable(address(this)).transfer(smartcontractvalue);
        payable(_startup).transfer(firstInvestment);

        _mint(msg.sender, _iddoc);

        return sucess;
    }

    //investidor manda a segunda parte
    function restOftheInvestment(address _startup) external payable onlyMutuante {
        uint256 rest = (whoInvWhatStartup[msg.sender][_startup].value * 49) / 100; //49% contrato
        payable(_startup).transfer(rest);
    }

    //pagamento da startup para a empresa, caso depois do prazo final multa de 20%
    function payInvestor(address _investor) external payable {
        //multa de 20% do valor da proposta do prazo final, ou seja 12 ether
        uint256 LatepaymentFee = (whoInvWhatStartup[_investor][msg.sender].value * 20) / 100;

        uint256 latevalue = whoInvWhatStartup[_investor][msg.sender].value + LatepaymentFee;

        unchecked {
            mutuarios[msg.sender].investedAmount -= msg.value;
        }

        if (block.timestamp > whoInvWhatStartup[_investor][msg.sender].finalTimeInvest) {
            require(msg.value == latevalue, "amount must be paid with the late fee more 20%");
            payable(_investor).transfer(latevalue);
        } else {
            payable(_investor).transfer(msg.value);
        }
    }

    //só pode retirar as quotas de garantia quando
    function withdrawQuotas() external authorizeWithdrawalQuotas {
        if (!mutuarios[msg.sender].captation) revert OnlyafterInvestmentFunding();
        uint256 quotas = tokenQ().balanceOf(address(this));
        tokenQ().safeTransfer(msg.sender, quotas);
    }

    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Returns
    /// -----------------------------------------------------------------------

    //Mutuario consegue acompanhar peloa endereço da startup o valor de aceite e o tempo que foi estipulado para pagar
    function seeInvestinYouStartup(address _startup)
        public
        view
        onlyAuthorized
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            whoInvWhatStartup[msg.sender][_startup].value,
            whoInvWhatStartup[msg.sender][_startup].finalTimeInvest,
            mutuarios[_startup].captation
        );
    }

    //conseguimos ver qual investidor esta busacando investir e com os valores e se está procurando ou não investimento
    function returnInvestors(address _investor)
        public
        view
        onlyAuthorized
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            mutuantes[_investor].numInvestment,
            mutuantes[_investor].cnpjoucpf,
            mutuantes[_investor].lookingFor
        );
    }

    //conseguimos ver a startup que quer ivestimento e se ela já alcançou o valor solicitado
    function returnStartupWantInvest(address _startup)
        public
        view
        onlyAuthorized
        returns (
            bool,
            uint256,
            uint256,
            ERC20,
            uint256
        )
    {
        return (
            mutuarios[_startup].captation,
            mutuarios[_startup].targetValue,
            mutuarios[_startup].numInvest,
            mutuarios[_startup].quotas,
            mutuarios[_startup].minValue
        );
    }

    /// -----------------------------------------------------------------------
    /// WithdrawERC20 and withdrawETH
    /// -----------------------------------------------------------------------

    function withdrawETH() external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);

        emit FundsWithdrawn();
    }

    function withdrawERC20(ERC20 tokene) external onlyOwner {
        uint256 balance = tokene.balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(tokene, address(this), msg.sender, balance);

        emit FundsWithdrawn();
    }

    function pausedoff()onlyOwner external{
        pause = true;
    }

    function mintOmnesParticipation(uint id)external pausedcontract{
        _mint(msg.sender, id);
    }
}
