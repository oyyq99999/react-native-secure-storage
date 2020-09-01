package li.yunqi.rnsecurestorage.cipherstorage;

import androidx.annotation.NonNull;

import li.yunqi.rnsecurestorage.exceptions.CryptoFailedException;

/**
 * Created by ouyangyunqi on 2018/3/26.
 */

public interface CipherStorage {

    abstract class CipherResult<T> {
        public final String key;
        public final T value;

        public CipherResult(String key, T value) {
            this.key = key;
            this.value = value;
        }
    }

    class EncryptionResult extends CipherResult<byte[]> {
        public CipherStorage cipherStorage;

        public EncryptionResult(String key, byte[] value, CipherStorage cipherStorage) {
            super(key, value);
            this.cipherStorage = cipherStorage;
        }
    }

    class DecryptionResult extends CipherResult<String> {
        public DecryptionResult(String key, String value) {
            super(key, value);
        }
    }

    String charsetName = "UTF-8";

    EncryptionResult encrypt(@NonNull String service, @NonNull String key, @NonNull String value) throws CryptoFailedException;

    DecryptionResult decrypt(@NonNull String service, @NonNull String key, @NonNull byte[] valueBytes) throws CryptoFailedException;

    String getCipherStorageName();

    int getMinSupportedApiLevel();

}
