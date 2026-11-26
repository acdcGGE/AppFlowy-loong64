//! Minimal drop-in replacement for the parts of `jsonwebtoken` 8.x that
//! AppFlowy uses (HS256/384/512 encode + decode). `ring` has no LoongArch64
//! support, so this shim implements HMAC via RustCrypto crates instead.

use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use hmac::{Hmac, Mac};
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use sha2::{Sha256, Sha384, Sha512};

pub mod errors {
    use std::fmt;

    #[derive(Debug)]
    pub struct Error(pub String);

    impl fmt::Display for Error {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            write!(f, "{}", self.0)
        }
    }

    impl std::error::Error for Error {}

    pub type Result<T> = std::result::Result<T, Error>;
}

use errors::{Error, Result};

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum Algorithm {
    HS256,
    HS384,
    HS512,
}

impl Default for Algorithm {
    fn default() -> Self {
        Algorithm::HS256
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Header {
    pub alg: Algorithm,
    pub typ: Option<String>,
}

impl Default for Header {
    fn default() -> Self {
        Header {
            alg: Algorithm::HS256,
            typ: Some("JWT".to_string()),
        }
    }
}

pub struct EncodingKey(Vec<u8>);

impl EncodingKey {
    pub fn from_secret(secret: &[u8]) -> Self {
        EncodingKey(secret.to_vec())
    }
}

pub struct DecodingKey(Vec<u8>);

impl DecodingKey {
    pub fn from_secret(secret: &[u8]) -> Self {
        DecodingKey(secret.to_vec())
    }
}

pub struct Validation {
    pub algorithms: Vec<Algorithm>,
    pub validate_exp: bool,
    pub leeway: u64,
}

impl Validation {
    pub fn new(alg: Algorithm) -> Self {
        Validation {
            algorithms: vec![alg],
            validate_exp: true,
            leeway: 60,
        }
    }
}

#[derive(Debug)]
pub struct TokenData<T> {
    pub header: Header,
    pub claims: T,
}

macro_rules! hmac_sign {
    ($hash:ty, $key:expr, $data:expr) => {{
        let mut mac = <Hmac<$hash>>::new_from_slice($key).map_err(|e| Error(e.to_string()))?;
        mac.update($data);
        Ok::<Vec<u8>, Error>(mac.finalize().into_bytes().to_vec())
    }};
}

fn sign(alg: Algorithm, key: &[u8], data: &[u8]) -> Result<Vec<u8>> {
    match alg {
        Algorithm::HS256 => hmac_sign!(Sha256, key, data),
        Algorithm::HS384 => hmac_sign!(Sha384, key, data),
        Algorithm::HS512 => hmac_sign!(Sha512, key, data),
    }
}

fn b64_decode(s: &str) -> Result<Vec<u8>> {
    URL_SAFE_NO_PAD
        .decode(s)
        .map_err(|e| Error(format!("invalid base64 segment: {e}")))
}

pub fn encode<T: Serialize>(header: &Header, claims: &T, key: &EncodingKey) -> Result<String> {
    let header_json = serde_json::to_vec(header).map_err(|e| Error(e.to_string()))?;
    let claims_json = serde_json::to_vec(claims).map_err(|e| Error(e.to_string()))?;
    let signing_input = format!(
        "{}.{}",
        URL_SAFE_NO_PAD.encode(header_json),
        URL_SAFE_NO_PAD.encode(claims_json)
    );
    let signature = sign(header.alg, &key.0, signing_input.as_bytes())?;
    Ok(format!(
        "{}.{}",
        signing_input,
        URL_SAFE_NO_PAD.encode(signature)
    ))
}

pub fn decode<T: DeserializeOwned>(
    token: &str,
    key: &DecodingKey,
    validation: &Validation,
) -> Result<TokenData<T>> {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err(Error("invalid JWT: expected 3 segments".into()));
    }
    let header: Header = serde_json::from_slice(&b64_decode(parts[0])?)
        .map_err(|e| Error(format!("invalid JWT header: {e}")))?;
    if !validation.algorithms.contains(&header.alg) {
        return Err(Error("JWT algorithm not allowed".into()));
    }
    let signing_input = format!("{}.{}", parts[0], parts[1]);
    let expected = sign(header.alg, &key.0, signing_input.as_bytes())?;
    let actual = b64_decode(parts[2])?;
    if expected.len() != actual.len() {
        return Err(Error("invalid JWT signature".into()));
    }
    let mut diff = 0u8;
    for (a, b) in expected.iter().zip(actual.iter()) {
        diff |= a ^ b;
    }
    if diff != 0 {
        return Err(Error("invalid JWT signature".into()));
    }

    let claims_json = b64_decode(parts[1])?;
    if validation.validate_exp {
        let value: serde_json::Value = serde_json::from_slice(&claims_json)
            .map_err(|e| Error(format!("invalid JWT claims: {e}")))?;
        if let Some(exp) = value.get("exp").and_then(|v| v.as_i64()) {
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs() as i64)
                .unwrap_or(0);
            if now > exp + validation.leeway as i64 {
                return Err(Error("JWT expired".into()));
            }
        }
    }
    let claims: T = serde_json::from_slice(&claims_json)
        .map_err(|e| Error(format!("invalid JWT claims: {e}")))?;
    Ok(TokenData { header, claims })
}
