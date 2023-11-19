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
parser.add_argument("-i", "--input", type=str, required=True, help="input csv file")
parser.add_argument("-o", "--output", type=str, required=True, help="output csv file")
args = parser.parse_args()

logging.basicConfig(filename=f"{args.output}.log",
                    format="%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s",
                    datefmt="%H:%M:%S",
                    filemode="w",
                    level=logging.DEBUG)
logger = logging.getLogger('rating_log')

openai.util.logger.setLevel(logging.INFO)
logging.getLogger("urllib3").setLevel(logging.INFO)

QUERY = """Human rates will be given three paragraphs of scientific articles, and they will have to categorize each paragraph into four categories, \
        depending on how they relate to the concept of memory decay. The concept of memory decay in psychology describe the theory that \
        memories traces are stored with an initial strength value and that this strength decays passively over time unless it is reactivated. \
        They will receive the following instructions: Instructions for human raters: You will read an articcle about human memory and you \
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
        assuming it's true? If so, respond 'ambiguous'. \
        Only assign this category if 'tacit_acceptance' doesn't fit.\n\n \
        Provide a clear category label ("ambiguous" or "support" or "against" or "tacit acceptance") on the first line for the paragraph below followed by your rationale in a new paragraph."""


def log_backoff_exception(details):
    details["filename"] = details["kwargs"]["filename"]
    logger.error("Backing off {wait:0.1f} seconds after {tries} tries for file '{filename}'".format(**details))


# access OpenAI API in exponential time intervals
@backoff.on_exception(backoff.expo, OpenAIError, on_backoff=log_backoff_exception, logger="rating_log")
def completion_with_backoff(**kwargs):
    args = kwargs.copy()
    args.pop("filename")
    return openai.ChatCompletion.create(**args)

def chatGPT_rate_category(query, paragraph, filename):
    logger.info(f"Iteration {i+1} for {filename}")
    messages = [{"role": "system", "content" : query},
                {"role": "user", "content" : paragraph},
                ]
    
    # define parameters
    model_engine = "gpt-4"
    temperature = 0.3

    # submit the QUERY
    completion = completion_with_backoff(
        filename = filename,
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
        category_labels = {"ambiguous": 0, "against": 1, "support": 2, "tacit_acceptance": 3}

        if rating.lower() in category_labels:
            category_id = category_labels[rating.lower()]
        else:
            category_id = "NA"
    
    except Exception as e:
        category_id = "NA"
        rationale = "NA"
        print(f"Error occured during rating evaluation: {e}")

    return category_id, rationale


if __name__ == "__main__":
    load_dotenv()

    # set OpenAI key
    openai.api_key = os.getenv("GPT4_KEY")

    input_csv = args.input

    print(f"READING FILE {input_csv}...\n")
    logger.info(f"READING FILE {input_csv}")

    # start populating dataframe list
    input = pd.read_csv(input_csv)
    
    # add required columns to dataframe
    print("RATING ARTICLES...\n")
    logger.info(f"RATING ARTICLES")
    dfs = []
    # rate relevance and calculate mean of relevance ratings for each dataframe
    for i, row in input.iterrows():
        print(f"RATING {row['filename']} ({i}/{len(input)}) ...")
        logger.info(f"RATING {row['filename']} ({i}/{len(input)})")

        for p in tqdm(range(3), leave=False):
            paragraph = input.loc[i, f"p{p+1}"]
            category_id, rationale = chatGPT_rate_category(QUERY, paragraph, row["filename"])
            input.at[i, f"p{p+1}_rating_category"] = category_id
            input.at[i, f"p{p+1}_rating_rationale"] = rationale

        # saving to csv as safety
        logger.info(f"SAVING RATINGS for {row['filename']}")
        df_final = input.to_csv(f"{args.output}.csv", index=False)
    
    print("DONE")

