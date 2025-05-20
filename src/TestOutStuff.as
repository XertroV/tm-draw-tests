#if FALSE
void TestOutStuff() {
    uint v = 2;
    RetValPlus1(v, v);
    assert_eq(v, 3, "simple +1");

    RetValPlus1(v, v);
    assert_eq(v, 4, "simple +1 repeated");

    RetVal_RecursivePlus1(v, v);
    assert_eq(v, 5, "recursive +1");

    print("\\$8f8 IT WORKED");
}

void assert_eq(uint a, uint b, const string &in msg) {
    if (a != b) {
        throw(msg);
    }
}

void RetValPlus1(uint &out oVal, uint inVal) {
    oVal = inVal + 1;
}

void RetVal_RecursivePlus1(uint &out oVal, uint inVal) {
    RetValPlus1(oVal, inVal);
}
#endif
