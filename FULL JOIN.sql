Select ID, name FROM [Potential_Buyers General]
INNER JOIN Assessment
ON [Potential_Buyers General].ID = Assessment.Customer_ID AND [Potential_Buyers General].Name = Assessment.Customer_Name;