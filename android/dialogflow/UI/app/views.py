import dialogflow
import config
from flask import request, render_template, request
from app import app

@app.route('/')
def index():
    '''
    Home page
    '''
    language_code=request.args.get('locale')
    if not (language_code):
        language_code="en"
    return render_template('index.html', value=language_code)

@app.route('/get_intent_response' , methods=['GET'])
def get_intent_response():
    session_client = dialogflow.SessionsClient()
    session = session_client.session_path(config.PROJECT_ID, request.args["sessionid"])
    language_code=request.args.get('locale')
    if not (language_code):
        language_code="en"
    text_input = dialogflow.types.TextInput(text=request.args["input_string"], language_code=language_code)
    query_input = dialogflow.types.QueryInput(text=text_input)
    response = session_client.detect_intent(
        session=session, query_input=query_input)
    result = response.query_result.fulfillment_text
    intent_name=response.query_result.intent.display_name
    out=result+"###"+intent_name+"###"+language_code
    print("Intent Name",response.query_result.intent.display_name)
    print("Fulfillment Text : ", result)
    return out

