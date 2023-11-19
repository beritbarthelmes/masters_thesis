# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

import pandas as pd
from lxml import etree

def get_infos_by_doi(doi):
    doi = root.find(f".//ui[.='{doi}']")
    print(doi)
    artinfo = doi.getparent()
    title = artinfo.find('.//atl').text
    print(title)
    return pd.DataFrame(columns = ['filename', 'title', 'abstract', 'DOI', 'date', 'authors'])


df = pd.read_csv("../test.csv", skipinitialspace=True)
tree = etree.parse("../ebsco_articles.xml")
root = tree.getroot()
final_df = pd.DataFrame(columns = ['filename', 'title', 'abstract', 'DOI', 'date', 'authors'])

j = 0
df["date"] = ""
for i, row in df.iterrows():
    doi = str(row['DOI'])
    doi = doi.lower()
    doiEle = root.xpath(f'.//ui[contains(translate(., "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "{doi}")]')
    doiEle = doiEle[0] if len(doiEle) == 1 else None

    title = str(row['title'])
    title = title.lower().replace('"', '')
    titleEle = root.xpath(f'.//btl[contains(translate(., "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "{title}")]')
    titleEle = titleEle[0] if len(titleEle) == 1 else None
    if doiEle is not None:
        control_info = doiEle.getparent().getparent()
        title = control_info.find('.//atl').text
        df.at[i,'title'] = title

        authors = ', \n'.join([author.text for author in control_info.findall('.//au')])
        df.at[i,'authors'] = authors

        date = control_info.find('.//dt').attrib
        date = f"{date['year']}-{date['month']}-{date['day']}"
        df.loc[i,'date'] = date

    elif titleEle is not None:
        control_info = titleEle.getparent().getparent()
        title = control_info.find('.//atl').text
        df.at[i,'title'] = title

        authors = ', \n'.join([author.text for author in control_info.findall('.//au')])
        df.at[i,'authors'] = authors

        date = control_info.find('.//dt').attrib
        date = f"{date['year']}-{date['month']}-{date['day']}"
        df.at[i,'date'] = date
    
    else:
        j+=1

    
print(j)

df.to_csv('../test_final.csv', index=False)