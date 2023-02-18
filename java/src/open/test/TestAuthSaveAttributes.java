package com.easydataservices.open.test;

import java.util.ArrayList;
import java.util.Arrays;
import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.auth.AuthAttributesDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.auth.StoreAttribute;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for testing the ATTRIBUTES.SAVE_ATTRIBUTES procedure.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthSaveAttributes extends TestAuthPayload {
  private AuthControlDao authControlDao;
  private AuthAttributesDao authAttributesDao;
  private String sessionIdPrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authAttributesDao = new AuthAttributesDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadUniqueId() + "_";
  }

  public void payload(int iteration) throws Exception {
    ArrayList<StoreAttribute> attributeList = new ArrayList<StoreAttribute>();
    String sessionId = sessionIdPrefix + iteration;
    StoreSession session = new StoreSession(sessionId);
    authControlDao.addSession(
      session.getSessionId(), 
      new Object[] {
        null,
        session.getAuthName(),
        null,
        session.getPropertiesJson()
      }
    );
    StoreAttribute attribute = new StoreAttribute("test.attribute");
    attribute.setObject("iteration:" + iteration);
    attributeList.add(attribute);
    int p = iteration % 6;
    StoreAttribute[] sessionAttributes = new StoreAttribute[7];
    for (int i = 0; i <= p; i++) {
      int size = ((int) Math.pow(2, i + 1)) * 32000;
      char[] charArray = new char[size];
      Arrays.fill(charArray, '*');
      String attributeName = "test.iteration." + (i + 1);
      sessionAttributes[i] = new StoreAttribute(attributeName);
      sessionAttributes[i].setObject("large object:" + new String(charArray) + attributeName);
      attributeList.add(sessionAttributes[i]);  
    }
    authAttributesDao.saveAttributes(sessionId, attributeList);
    if (iteration > 200 && iteration % 7 == 0) {
      String oldSessionId = sessionIdPrefix + (iteration - 200);
      ArrayList<StoreAttribute> oldAttributeList = new ArrayList<StoreAttribute>();
      StoreAttribute oldAttribute = new StoreAttribute("test.attribute");
      oldAttributeList.add(oldAttribute);
      authAttributesDao.saveAttributes(oldSessionId, oldAttributeList);
    }
  }
}