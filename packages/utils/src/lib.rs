#![doc = include_str!("../README.md")]
#![deny(missing_docs)]
#![deny(clippy::nursery, clippy::pedantic, warnings)]

use ibc_core_commitment_types::{merkle::MerkleProof, proto::ics23::CommitmentProof};
use tendermint::merkle::proof::ProofOps;

/// Convert a Tendermint proof to an ICS Merkle proof.
///
/// # Errors
/// Returns a decoding error if the prost merge.
pub fn convert_tm_to_ics_merkle_proof(
    tm_proof: &ProofOps,
) -> Result<MerkleProof, prost::DecodeError> {
    let mut proofs = Vec::with_capacity(tm_proof.ops.len());

    for (i, op) in tm_proof.ops.iter().enumerate() {
        let mut parsed = CommitmentProof::default();
        prost::Message::merge(&mut parsed, op.data.as_slice())?;
        proofs[i] = parsed;
    }

    Ok(MerkleProof { proofs })
}
