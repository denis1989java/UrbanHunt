package com.urbanhunt.app;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import com.google.cloud.firestore.Firestore;

@SpringBootTest
class UrbanHuntApplicationTests {

    @MockBean
    private Firestore firestore;

    @Test
    void contextLoads() {
    }

}
