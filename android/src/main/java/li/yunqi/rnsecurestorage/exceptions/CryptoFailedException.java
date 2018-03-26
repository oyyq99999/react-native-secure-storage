package li.yunqi.rnsecurestorage.exceptions;

/**
 * Created by ouyangyunqi on 2018/3/26.
 */

public class CryptoFailedException extends Exception {

    public CryptoFailedException(String message) {
        super(message);
    }

    public CryptoFailedException(String message, Throwable t) {
        super(message, t);
    }
}
