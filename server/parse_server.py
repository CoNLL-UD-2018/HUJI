import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_agg import FigureCanvasAgg

from io import BytesIO
from xml.etree.ElementTree import fromstring, tostring
from urllib.parse import quote
from base64 import b64encode
import jinja2
from flask import Flask, render_template, Response, request
import flask_assets
from flask_compress import Compress
from webassets.ext.jinja2 import AssetsExtension
from webassets import Environment as AssetsEnvironment

from ucca.convert import from_text, to_standard, from_standard
from ucca.textutil import indent_xml
from ucca.visualization import draw
from tupa.parse import Parser

SCRIPT_DIR = os.path.dirname(__file__)

app = Flask(__name__)
assets = flask_assets.Environment()
assets.init_app(app)
assets_env = AssetsEnvironment("./static/", "/static")
jinja_environment = jinja2.Environment(
    autoescape=True,
    loader=jinja2.FileSystemLoader(os.path.join(SCRIPT_DIR, "templates")),
    extensions=[AssetsExtension])
jinja_environment.assets_environment = assets_env
Compress(app)

app.parser = None
PARSER_MODEL = os.getenv("PARSER_MODEL", os.path.join(SCRIPT_DIR, "..", "models/bilstm"))
PARSER_TYPE = os.getenv("PARSER_TYPE", "bilstm")


def get_parser():
    if app.parser is None:
        print("Initializing parser...")
        print("PARSER_MODEL=" + PARSER_MODEL)
        print("PARSER_TYPE=" + PARSER_TYPE)
        app.parser = Parser(PARSER_MODEL, PARSER_TYPE)
    return app.parser


@app.route("/")
def parser_demo():
    return render_template("demo.html")


@app.route("/parse", methods=["POST"])
def parse():
    text = request.values["input"]
    print("Parsing text: '%s'" % text)
    in_passage = next(from_text(text))
    out_passage = next(get_parser().parse(in_passage))
    root = to_standard(out_passage)
    xml = tostring(root).decode()
    return Response(indent_xml(xml), headers={"Content-Type": "xml/application"})


@app.route("/visualize", methods=["POST"])
def visualize():
    xml = request.get_data()
    passage = from_standard(fromstring(xml))
    print("Visualizing passage %s: %s" % (passage.ID, passage.layer("1").top_node))
    canvas = FigureCanvasAgg(plt.figure())
    draw(passage)
    image = BytesIO()
    canvas.print_png(image)
    data = b64encode(image.getvalue()).decode()
    return Response(quote(data.rstrip("\n")))


session_opts = {
    "session.type": "file",
    "session.cookie_expires": 60 * 24 * 60 * 2,  # two days in seconds
    "session.data_dir": "./data",
    "session.auto": True
}

if __name__ == "__main__":
    app.run(debug=True, host=os.getenv("IP", "ucca"), port=int(os.getenv("PORT", 5001)))
