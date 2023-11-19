# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

import os 
import xml.etree.ElementTree as ET
import pandas as pd
import openai
import backoff
from tqdm import tqdm
import argparse
import numpy as np
from openai.error import OpenAIError
import logging
from dotenv import load_dotenv

# create argument parser
parser = argparse.ArgumentParser()
parser.add_argument("output_filename", type=str, help="filename of output file")
parser.add_argument("-i", "--input", type=str, required=True, help="directory with input files")
parser.add_argument("-o", "--output", type=str, required=True, help="directory of output file")
parser.add_argument("-iter", "--iterations", type=int, required=False, default=10, help="number of iterations per article")
args = parser.parse_args()

logging.basicConfig(filename=f"{args.output}{args.output_filename}.log",
                    format="%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s",
                    datefmt="%H:%M:%S",
                    filemode="w",
                    level=logging.DEBUG)
logger = logging.getLogger('rating_log')

openai.util.logger.setLevel(logging.INFO)
logging.getLogger("urllib3").setLevel(logging.INFO)

QUERY = """Human rates will be given a set of scientific articles, and they will have to categorize each article into four categories, \
        depending on how they relate to the concept of memory decay. The concept of memory decay in psychology describe the theory that \
        memories traces are stored with an initial strength value and that this strength decays passively over time unless it is reactivated. \
        They will receive the following instructions: Instructions for human raters: You will read an article about human memory and you \
        should classify each article depending on how it discusses the idea that the strength of memories decay passively over time. \
        You can assign one of four categories to the text. Use the following questions in this order to assign the categories: - \
        Does the text disagree with the idea that memory decay exists or disagree with the idea that it is the major cause of forgetting? \
        If so, respond 'against'. \
        Only assign this category if the text explicitly rejects all forms of memory decay, rather than just some version of it. \
        Does the article implicitly assume that the concept of memory decay is true and then builds on it? If so, respond 'tacit_acceptance'. \
        Assign this category if the text doesn't explicitly mention or discuss evidence for or against the general idea. \
        Does the article explicitly agree with or provide evidence for the idea that memory decays over time? If so, respond 'support'. \
        Only assign this category if the text specifically discusses evidence for the idea, or explicitly agrees that the idea is true. \
        Does the text explicitly mention memory decay as one of several possibilities without discussing evidence for or against or without \
        assuming it's true? If so, respond 'neutral'. \
        Only assign this category if 'tacit_acceptance' doesn't fit.\n\n \
        We first have to select which articles to present to human raters. We only want to show them articles that can be categorized in one \
        of the categories above. If articles cannot be categorized in one of the categories above, they are irrelevant. We have several thousand \
        scientific articles, but many of them are not relevant for the QUERY above. \Some articles are irrelevant because they are done with \
        non-human animals. Others are irrelevant because they do not mention memory decay explicitly. \Others are irrelevant because they discuss \
        degradation of memory in old age. We will give you an abstract and your task is to rate the abstract as relevant or irrelevant for the \
        human raters. \
        Provide a clear category label ("relevant" or "irrelevant") on the first line for the abstract below followed by your rationale in a new paragraph."""


def log_backoff_exception(details):
    details["filename"] = details["kwargs"]["filename"]
    logger.error("Backing off {wait:0.1f} seconds after {tries} tries for file '{filename}'".format(**details))

# access OpenAI API in exponential time intervals
@backoff.on_exception(backoff.expo, OpenAIError, on_backoff=log_backoff_exception, logger="rating_log")
def completion_with_backoff(**kwargs):
    args = kwargs.copy()
    args.pop("filename")
    return openai.ChatCompletion.create(**args)


def chatGPT_rate_relevance(query, df, iterations=10):
    ratings = []
    for i in tqdm(range(iterations), leave=False):
        logger.info(f"Iteration {i+1} for {df['filename'][0]}")
        messages = [{"role": "system", "content" : query},
                    {"role": "user", "content" : df["abstract"][0]},
                    ]
        
        # define parameters
        model_engine = "gpt-4"
        temperature = 0.3

        # submit the QUERY
        completion = completion_with_backoff(
            filename = df["filename"][0],
            model = model_engine,
            messages = messages,
            temperature = temperature)
        
        result = completion.choices[0].message.content

        try:
            # process result
            result = result.split('\n\n')
            if len(result) == 2:
                rating = result[0]
                rationale = result[1]
            else:
                rating = "NA"
                rationale = "NA"

            # translate rating to distinct id
            category_labels = {"irrelevant": 0, "relevant": 1}

            if rating.lower() in category_labels:
                category_id = category_labels[rating.lower()]
            else:
                category_id = "NA"

            # write id and rationale to dataframe
            df[f"rating_relevance{i+1}"] = category_id
            df[f"rationale{i+1}"] = rationale
        
        except Exception as e:
            df[f"rating_relevance{i+1}"] = "NA"
            df[f"rationale{i+1}"] = "NA"
            print(f"Error occured during rating evaluation: {e}")
        
        ratings.append(category_id)

    return ratings


if __name__ == "__main__":
    load_dotenv()

    # set OpenAI key
    openai.api_key = os.getenv("GPT4_KEY")

    xml_dir = args.input
    dfs = []

    print(f"READING FILES in {args.input}...\n")
    logger.info(f"READING FILES in {args.input}")

    # start populating dataframe list
    for file in os.listdir(xml_dir):
        directory = os.fsdecode(xml_dir)
        filename = os.fsdecode(file)
        path = os.path.join(directory, filename)
        if filename.endswith(".xml"):
            tree = ET.parse(path)
            root = tree.getroot()

            title = root.find(".//{http://www.tei-c.org/ns/1.0}fileDesc//{http://www.tei-c.org/ns/1.0}title")
            if title is not None and title.text is not None:
                title = title.text
            else:
                title = "NA"

            # finds all p tags in namespace http://www.tei-c.org/ns/1.0 and creates a list of these tags.
            abstract = root.find(".//{http://www.tei-c.org/ns/1.0}abstract")

            # extract content and save into dictionary
            if abstract is not None and abstract.text is not None:
                abstract = ''.join(abstract.itertext()).strip("\n")
            else:
                abstract = "NA"

            doi = root.find(".//{http://www.tei-c.org/ns/1.0}idno[@type='DOI']")
            if doi is not None and doi.text is not None:
                doi = doi.text
            else:
                doi = "NA"

            date = root.find(".//{http://www.tei-c.org/ns/1.0}fileDesc//{http://www.tei-c.org/ns/1.0}date")
            if date is not None and date.text is not None:
                date = date.text
            else:
                date = "NA"

            authors = root.findall(".//{http://www.tei-c.org/ns/1.0}fileDesc//{http://www.tei-c.org/ns/1.0}persName")

            if authors:
                authors = "\n".join([' '.join(a.itertext()) for a in authors])
            else:
                authors = "NA"

            df = pd.DataFrame({"filename": filename, "title": title, "abstract": abstract, "DOI": doi, "date": date, "authors": authors}, index=[0])
            dfs.append(df)


    print("RATING ARTICLES...\n")
    logger.info(f"RATING ARTICLES")
    # rate relevance and calculate mean of relevance ratings for each dataframe
    for i, df in enumerate(tqdm(dfs)):
        print(f"RATING {df['filename'][0]} ({i}/{len(dfs)}) ...")
        logger.info(f"RATING {df['filename'][0]} ({i}/{len(dfs)})")
        ratings = chatGPT_rate_relevance(QUERY, df, args.iterations)
        ratings = [x for x in ratings if type(x) == int]
        if len(ratings) > 0:
            mean = np.asarray(ratings, dtype=int).mean()
        else:
            mean = "NA"
        df["mean_rating_relevance"] = mean

        # saving to csv as safety
        logger.info(f"SAVING RATINGS for {df['filename'][0]}")
        df_final = pd.concat(dfs, ignore_index=True)
        df_final.to_csv(f"{args.output}{args.output_filename}.csv", index=False)
    
    print("DONE")

