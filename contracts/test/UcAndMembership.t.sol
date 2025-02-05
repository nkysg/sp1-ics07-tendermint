// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// solhint-disable-next-line no-global-import
import "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { MembershipTest } from "./MembershipTest.sol";

contract SP1ICS07UpdateClientAndMembershipTest is MembershipTest {
    using stdJson for string;

    SP1MembershipAndUpdateClientProof public proof;

    function setUp() public {
        setUpTestWithFixtures("uc_and_memberships_fixture.json");

        proof = abi.decode(fixture.membershipProof.proof, (SP1MembershipAndUpdateClientProof));

        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));

        ClientState memory clientState = mockIcs07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight < output.updateClientOutput.newHeight.revisionHeight);
    }

    function verifyMembershipValue() public view returns (bytes memory) {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));

        return output.kvPairs[0].value;
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_Valid_UpdateClientAndVerifyMembership() public {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        // set a correct timestamp
        vm.warp(output.updateClientOutput.env.now + 300);

        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyMembershipPath,
            value: verifyMembershipValue()
        });

        // run verify
        ics07Tendermint.membership(membershipMsg);

        console.log("UpdateClientAndVerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight == output.updateClientOutput.newHeight.revisionHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash =
            ics07Tendermint.getConsensusStateHash(output.updateClientOutput.newHeight.revisionHeight);
        assert(consensusHash == keccak256(abi.encode(output.updateClientOutput.newConsensusState)));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_Valid_UpdateClientAndVerifyNonMembership() public {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        // set a correct timestamp
        vm.warp(output.updateClientOutput.env.now + 300);

        MsgMembership memory nonMembershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyNonMembershipPath,
            value: bytes("")
        });

        // run verify
        ics07Tendermint.membership(nonMembershipMsg);

        console.log("UpdateClientAndVerifyNonMembership gas used: ", vm.lastCallGas().gasTotalUsed);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight == output.updateClientOutput.newHeight.revisionHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash =
            ics07Tendermint.getConsensusStateHash(output.updateClientOutput.newHeight.revisionHeight);
        assert(consensusHash == keccak256(abi.encode(output.updateClientOutput.newConsensusState)));
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_Valid_CachedUpdateClientAndMembership() public {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        // set a correct timestamp
        vm.warp(output.updateClientOutput.env.now + 300);

        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyMembershipPath,
            value: verifyMembershipValue()
        });

        // run verify
        ics07Tendermint.membership(membershipMsg);

        ClientState memory clientState = ics07Tendermint.getClientState();
        assert(clientState.latestHeight.revisionHeight == output.updateClientOutput.newHeight.revisionHeight);
        assert(clientState.isFrozen == false);

        bytes32 consensusHash =
            ics07Tendermint.getConsensusStateHash(output.updateClientOutput.newHeight.revisionHeight);
        assert(consensusHash == keccak256(abi.encode(output.updateClientOutput.newConsensusState)));

        // resubmit the same proof
        ics07Tendermint.membership(membershipMsg);

        console.log("Cached UpdateClientAndVerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);

        MsgMembership memory nonMembershipMsg = MsgMembership({
            proof: abi.encode(fixture.membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyNonMembershipPath,
            value: bytes("")
        });

        // run verify
        ics07Tendermint.membership(nonMembershipMsg);

        console.log("Cached UpdateClientAndNonVerifyMembership gas used: ", vm.lastCallGas().gasTotalUsed);
    }

    // Confirm that submitting a real proof passes the verifier.
    function test_Invalid_UpdateClientAndMembership() public {
        UcAndMembershipOutput memory output = abi.decode(proof.sp1Proof.publicValues, (UcAndMembershipOutput));
        // set a correct timestamp
        vm.warp(output.updateClientOutput.env.now + 300);

        SP1MembershipAndUpdateClientProof memory ucAndMemProof = proof;
        ucAndMemProof.sp1Proof.proof = bytes("invalid");

        MembershipProof memory membershipProof = MembershipProof({
            proofType: MembershipProofType.SP1MembershipAndUpdateClientProof,
            proof: abi.encode(ucAndMemProof)
        });

        MsgMembership memory membershipMsg = MsgMembership({
            proof: abi.encode(membershipProof),
            proofHeight: fixture.proofHeight,
            path: verifyNonMembershipPath,
            value: bytes("")
        });

        vm.expectRevert();
        ics07Tendermint.membership(membershipMsg);
    }
}
