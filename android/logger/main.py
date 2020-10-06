from flask import Flask, request, url_for, redirect, render_template, send_file, abort
import flask
import os
import re
import logging


app = Flask(__name__)
app.config["DEBUG"] = True
logging.basicConfig(level=logging.DEBUG)

@app.route('/', methods=['GET', 'POST'])
def home():
    message = request.json
    list_ = ["I_CW_ERROR", "A_CW_ERROR"]
    logcodes_list = ["A_CW_91002", "I_CW_91002", "I_CW_91001", "I_CW_91009", "A_CW_91001", "A_CW_91009"]
    try:
        if("CW_9100" in message['message']):
            if any(eachword in message['message'] for eachword in logcodes_list):
                logging.info(message)
            else:
                return ""
        elif any(word in message['message'] for word in list_):	
            logging.error(message)	
        else:
            logging.error(message)

    except Exception as e:
        # logging.info(e)
        logging.error(message)
        abort(500)
    return ""

# if __name__ == "__main__":
    # write_to_storage()
    # write_to_firestore("qwert-wertyu-ertyu","231346283","Hello logged")
    # app.run()
