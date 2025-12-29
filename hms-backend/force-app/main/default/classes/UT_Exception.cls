public class UT_Exception extends Exception {
    public static void throwError(String msg) {
        throw new UT_Exception(msg);
    }
}
